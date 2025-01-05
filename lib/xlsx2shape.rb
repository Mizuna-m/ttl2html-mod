#!/usr/bin/env ruby

require 'roo'

module XLSX2Shape
  def xlsx2shape(filename)
    shapes = {}
    prefix = { sh: 'http://www.w3.org/ns/shacl#' }
    xlsx = Roo::Excelx.new(filename)
    xlsx.each_with_pagename do |name, sheet|
      if name =~ /\Aprefix\z/i
        sheet.each do |row|
          prefix[row[0].to_s.intern] = row[1] unless row[1].empty?
        end
      else
        headers = sheet.row(1)
        uri = headers.first
        shapes[format_pvalue(uri, nil, prefix)] = ["#{format_pvalue(uri, nil, prefix)} a sh:NodeShape"]
        order = 1
        sheet.each_with_index do |row, _idx|
          row_h = map_xlsx_row_headers(row, headers)
          case row.first
          when 'sh:targetClass'
            if row[1]
              shapes[format_pvalue(uri, nil,
                                   prefix)] << "#{format_property('sh:targetClass', row[1], nil, prefix)}"
            end
          when 'sh:property'
            prop_values = []
            headers[1..-1].each do |prop|
              next if row_h[prop].empty?

              case prop
              when /@(\w+)\z/
                lang = Regexp.last_match(1)
                property_name = prop.sub(/@(\w+)\z/, '')
                prop_values << format_property(property_name, row_h[prop], lang, prefix)
              when 'sh:minCount', 'sh:maxCount'
                prop_values << format_property(prop, row_h[prop].to_i, nil, prefix)
              when 'sh:languageIn'
                # 言語リストの特別処理
                values = split_values(row_h[prop]).map { |e| format_pvalue(e, nil, prefix) }
                prop_values << %|  sh:languageIn (#{values.join(' ')})|
              when 'sh:uniqueLang'
                case row_h[prop]
                when 'true'
                  prop_values << '  sh:uniqueLang true'
                when 'false'
                  prop_values << '  sh:uniqueLang false'
                else
                  logger.warn "sh:uniqueLang value unknown: #{row_h[prop]} at #{uri}"
                end
              else
                # 通常のプロパティ処理
                prop_values << format_property(prop, row_h[prop], nil, prefix)
              end
            end
            prop_values << format_property('sh:order', order, nil, prefix)
            order += 1
            str = prop_values.join(";\n  ")
            shapes[format_pvalue(uri, nil, prefix)] << "  sh:property [\n  #{str}\n  ]"
          when 'sh:or'
            shapes[format_pvalue(uri, nil, prefix)] << "  sh:or (#{row[1..-1].select do |e|
              !e.empty?
            end.map { |e| format_pvalue(e, nil, prefix) }.join(' ')})"
          end
        end
      end
    end
    result = ''
    prefix.sort_by { |k, v| [k, v] }.each do |prefix, val|
      result << "@prefix #{prefix}: <#{val}>.\n"
    end
    shapes.sort_by { |uri, _val| uri }.each do |uri, _val|
      result << "\n"
      result << shapes[uri].join(";\n")
      result << ".\n"
    end
    result
  end

  def map_xlsx_row_headers(data_row, headers)
    hash = {}
    headers.each_with_index do |h, idx|
      hash[h] = data_row[idx].to_s
    end
    hash
  end

  def format_property(property, value, lang = nil, prefix = {})
    # 値を分割（改行のみ考慮）
    values = split_values(value).map do |v|
      v = v.strip if v.is_a?(String) # 文字列の場合のみ strip を適用
      format_pvalue(v, lang, prefix)
    end

    # 複数目的語をカンマ区切りで出力
    %(  #{property} #{values.join(', ')})
  end

  def split_values(value)
    if value.is_a?(Numeric)
      # 数値はそのまま返す
      [value]
    elsif value.to_s.include?("\n")
      # 改行で分割
      value.to_s.split("\n").map(&:strip)
    else
      # 改行がない場合はそのまま配列化
      [value.to_s.strip]
    end
  end

  def format_pvalue(value, lang = nil, _prefix = {})
    if value.is_a?(Numeric)
      # 数値はそのまま出力
      value.to_s
    elsif value =~ %r{\Ahttps?://}
      # IRIは山かっこで囲む
      %(<#{value}>)
    elsif value =~ /\A\w+:[\w\-.]+\Z/
      # QNameはそのまま出力
      value
    elsif value =~ /(.+?)@([a-zA-Z-]+)\z/
      # `値@言語タグ` の形式であれば言語タグ付きリテラルとして処理
      literal = ::Regexp.last_match(1).strip
      lang = ::Regexp.last_match(2)
      %("#{escape_turtle(literal)}"@#{lang})
    elsif value.include?('\@')
      # エスケープされた `@` を平文として扱う
      %("#{escape_turtle(value.gsub('\@', '@'))}")
    else
      # 通常のリテラル
      %("#{escape_turtle(value)}")
    end
  end

  def escape_turtle(str)
    # Turtleでエスケープする必要のある文字を処理
    str.gsub(/\\/) { '\\\\' }.gsub(/"/) { '\"' }
  end
end
