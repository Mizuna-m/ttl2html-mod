#!/usr/bin/env ruby

require "fileutils"
require "pathname"
require "erb"
require "i18n"
require "action_view"

module TTL2HTML
  class Template
    attr_reader :param
    include ERB::Util
    include I18n::Base
    include ActionView::Helpers::NumberHelper
    def initialize(template, param = {})
      @template = template
      @param = param.dup
      @template_path = [ Dir.pwd, File.join(Dir.pwd, "templates") ]
      @template_path << File.join(File.dirname(__FILE__), "..", "..", "templates")
      I18n.load_path << Dir[File.join(File.dirname(__FILE__), "..", "..", "locales") + "/*.yml"]
      I18n.load_path << Dir[File.expand_path("locales") + "/*.yml"]
      I18n.locale = @param[:locale] if @param[:locale]
    end
    def output_to(file, param = {})
      @param.update(param)
      @param[:output_file] = file
      dir = File.dirname(file)
      FileUtils.mkdir_p(dir) if not File.exist?(dir)
      open(file, "w") do |io|
        io.print to_html(@param)
      end
    end
    def to_html(param)
      param[:content] = to_html_raw(@template, param)
      layout_fname = "layout.html.erb"
      to_html_raw(layout_fname, param)
    end
    def to_html_raw(template, param)
      @param.update(param)
      template = find_template_path(template)
      tmpl = open(template){|io| io.read }
      erb = ERB.new(tmpl, nil, "-")
      erb.filename = template
      erb.result(binding)
    end

    def find_template_path(fname)
      if @param[:template_dir] and Dir.exist?(@param[:template_dir])
        @template_path.unshift(@param[:template_dir])
        @template_path.uniq!
      end
      @template_path.each do |dir|
        file = File.join(dir, fname)
        return file if File.exist? file
      end
      return nil
    end

    def expand_shape(data, uri, prefixes = {})
      return nil if not data[uri]
      return nil if not data[uri]["http://www.w3.org/ns/shacl#property"]
      result = data[uri]["http://www.w3.org/ns/shacl#property"].sort_by do |e|
        e["http://www.w3.org/ns/shacl#order"]
      end.map do |property|
        path = data[property]["http://www.w3.org/ns/shacl#path"].first
        shorten_path = path.dup
        prefixes.each do |prefix, val|
          if path.index(val) == 0
            shorten_path = path.sub(/\A#{val}/, "#{prefix}:")
          end
        end
        repeatable = false
        if data[property]["http://www.w3.org/ns/shacl#maxCount"]
          max_count = data[property]["http://www.w3.org/ns/shacl#maxCount"].first.to_i
          if max_count > 1
            repeatable = true
          end
        else
          repeatable = true
        end
        nodes = nil
        if data[property]["http://www.w3.org/ns/shacl#node"]
          node = data[property]["http://www.w3.org/ns/shacl#node"].first
          if data[node]["http://www.w3.org/ns/shacl#or"]
            node_or = data[data[node]["http://www.w3.org/ns/shacl#or"].first]
            node_mode = :or
            nodes = []
            nodes << expand_shape(data, node_or["http://www.w3.org/1999/02/22-rdf-syntax-ns#first"].first, prefixes)
            rest = node_or["http://www.w3.org/1999/02/22-rdf-syntax-ns#rest"].first
            while data[rest] do
              nodes << expand_shape(data, data[rest]["http://www.w3.org/1999/02/22-rdf-syntax-ns#first"].first, prefixes)
              rest = data[rest]["http://www.w3.org/1999/02/22-rdf-syntax-ns#rest"].first
            end
          else
            nodes = expand_shape(data, node, prefixes)
          end
          #p nodes
        end
        {
          path: path,
          shorten_path: shorten_path,
          name: get_language_literal(data[property]["http://www.w3.org/ns/shacl#name"]),
          example: data[property]["http://www.w3.org/2004/02/skos/core#example"] ? data[property]["http://www.w3.org/2004/02/skos/core#example"].first : nil,
          description: get_language_literal(data[property]["http://www.w3.org/ns/shacl#description"]),
          required: data[property]["http://www.w3.org/ns/shacl#minCount"] ? data[property]["http://www.w3.org/ns/shacl#minCount"].first.to_i > 0 : false,
          repeatable: repeatable,
          nodeKind: data[property]["http://www.w3.org/ns/shacl#nodeKind"] ? data[property]["http://www.w3.org/ns/shacl#nodeKind"].first : nil,
          nodes: nodes,
          node_mode: node_mode,
        }
      end
      template = "shape-table.html.erb"
      tmpl = Template.new(template)
      tmpl.to_html_raw(template, {properties: result})
    end

    # helper method:
    def uri_mapping_to_path(uri, suffix = ".html")
      path = nil
      if @param[:uri_mappings]
        @param[:uri_mappings].each do |mapping|
          local_file = uri.sub(@param[:base_uri], "")
          if mapping["regexp"] =~ local_file
            path = local_file.sub(mapping["regexp"], mapping["path"])
          end
        end
      end
      if path.nil?
        if suffix == ".html"
          if @param[:data_global] and @param[:data_global].keys.find{|e| e.start_with?(uri + "/") }
            path = uri + "/index"
          elsif uri.end_with?("/")
            path = uri + "index"
          else
            path = uri
          end
        else
          path = uri
        end
      end
      path = path.sub(@param[:base_uri], "") if @param[:base_uri]
      path << suffix
      path
    end
    def relative_path(dest)
      src = @param[:output_file]
      src = Pathname.new(src).relative_path_from(Pathname.new(@param[:output_dir])) if @param[:output_dir]
      path = Pathname(dest).relative_path_from(Pathname(File.dirname src))
      path = path.to_s + "/" if File.directory? path
      path
    end
    def relative_path_uri(dest_uri, base_uri)
      if dest_uri.start_with? base_uri
        dest = dest_uri.sub(base_uri, "")
        dest = uri_mapping_to_path(dest, "")
        relative_path(dest)
      else
        dest_uri
      end
    end
    def html_title(param)
      titles = []
      titles << param[:title]
      titles << param[:site_title]
      titles.compact.join(" - ")
    end
    def shorten_title(title, length = 140)
      if title.length > length
        title[0..length] + "..."
      else
        title
      end
    end
    def get_title(data, default_title = "no title")
      if @param[:title_property_perclass] and data["http://www.w3.org/1999/02/22-rdf-syntax-ns#type"]
        @param[:title_property_perclass].each do |klass, property|
          if data["http://www.w3.org/1999/02/22-rdf-syntax-ns#type"].include?(klass) and data[property]
            return shorten_title(get_language_literal(data[property]))
          end
        end
      end
      if @param[:title_property] and data[@param[:title_property]]
        return shorten_title(get_language_literal(data[@param[:title_property]]))
      end
      %w(
        http://www.w3.org/2000/01/rdf-schema#label
        http://purl.org/dc/terms/title
        http://purl.org/dc/elements/1.1/title
        http://schema.org/name
        http://www.w3.org/2004/02/skos/core#prefLabel
      ).each do |property|
        return shorten_title(get_language_literal(data[property])) if data[property]
      end
      default_title
    end
    def get_language_literal(object)
      if object.respond_to? :has_key?
        if object.has_key?(I18n.locale)
          object[I18n.locale]
        else
          object.values.first
        end
      elsif object.is_a? Array
        object.first
      else
        object
      end
    end
    def format_property(property, labels = {})
      if labels and labels[property]
        labels[property]
      else
        property.split(/[\/\#]/).last.capitalize
      end
    end
    def format_object(object, data)
      if object =~ /\Ahttps?:\/\//
        rel_path = relative_path_uri(object, param[:base_uri])
        if param[:data_global][object]
          "<a href=\"#{rel_path}\">#{get_title(param[:data_global][object]) or object}</a>"
        else
          "<a href=\"#{rel_path}\">#{object}</a>"
        end
      elsif object =~ /\A_:/ and param[:data_global][object]
        format_triples(param[:data_global][object])
      else
        object
      end
    end
    def format_triples(triples, type = :default)
      param_local = @param.dup.merge(data: triples)
      param_local[:type] = type
      if @param[:labels_with_class] and triples["http://www.w3.org/1999/02/22-rdf-syntax-ns#type"]
        @param[:labels_with_class].reverse_each do |k, v|
          triples["http://www.w3.org/1999/02/22-rdf-syntax-ns#type"].each do |entity_class|
            if entity_class == k
              v.each do |property, label_value|
                param_local[:labels] ||= {}
                param_local[:labels][property] = label_value
              end
            end
          end
        end
      end
      if @param[:orders_with_class] and triples["http://www.w3.org/1999/02/22-rdf-syntax-ns#type"]
        @param[:orders_with_class].reverse_each do |k, v|
          triples["http://www.w3.org/1999/02/22-rdf-syntax-ns#type"].each do |entity_class|
            if entity_class == k
              v.each do |property, order|
                param_local[:orders] ||= {}
                param_local[:orders][property] = order || Float::INFINITY
              end
            end
          end
        end
      end
      to_html_raw("triples.html.erb", param_local)
    end
    def format_version_info(version)
      param_local = @param.dup.merge(data: version)
      to_html_raw("version.html.erb", param_local)
    end
  end
end
