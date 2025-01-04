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
                lang = ::Regexp.last_match(1)
                property_name = prop.sub(/@(\w+)\z/, '')
                prop_values << format_property(property_name, row_h[prop], lang, prefix)
              when 'sh:minCount', 'sh:maxCount'
                prop_values << format_property(prop, row_h[prop].to_i, nil, prefix)
              when 'sh:languageIn'
                prop_values << "  sh:languageIn (#{row_h[prop].split.map do |e|
                  format_pvalue(e, nil, prefix)
                end.join(' ')})"
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

  def format_pvalue(value, lang = nil, prefix = {})
    str = ''
    if value.is_a? Hash
      result = ['[']
      array = []
      value.keys.sort.each do |k|
        array << format_property(k, value[k], nil, prefix)
      end
      result << array.join(";\n")
      result << '  ]'
      str = result.join("\n")
    elsif value.is_a? Integer
      str = value
    elsif value =~ %r{\Ahttps?://}
      str = %(<#{value}>)
    elsif value =~ /\A\w+:[\w\-.]+\Z/
      str = value
    elsif value =~ /\A(.+?)\^\^(\w+:\w+)\z/
      str = %("#{escape_turtle(::Regexp.last_match(1))}"^^#{::Regexp.last_match(2)})
    elsif prefix.any? { |_, v| value.start_with?(v) }
      # URI を prefix:qname に変換
      prefix.each do |key, val|
        return "#{key}:#{value.sub(val, '')}" if value.start_with?(val)
      end
    elsif lang
      str = %("#{escape_turtle(value)}"@#{lang})
    else
      str = %("#{escape_turtle(value)}")
    end
    str
  end

  def format_property(property, value, lang = nil, prefix = {})
    # value が文字列の場合は改行で分割して複数の目的語に対応
    values = if value.is_a?(String)
               value.split("\n").map { |v| format_pvalue(v.strip, lang, prefix) }
             else
               # 非文字列の場合はそのままフォーマット
               [format_pvalue(value, lang, prefix)]
             end
    # 複数の目的語をカンマ区切りで出力
    %(  #{property} #{values.join(', ')})
  end

  def escape_turtle(str)
    str.gsub(/\\/) { '\\\\' }.gsub(/"/) { '\"' }
  end
end
