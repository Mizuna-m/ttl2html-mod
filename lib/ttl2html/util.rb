module TTL2HTML
  module Util
    def uri_mapping_to_path(uri, param, suffix = ".html")
      path = nil
      if param[:uri_mappings]
        param[:uri_mappings].each do |mapping|
          local_file = uri.sub(param[:base_uri], "")
          if mapping["regexp"] =~ local_file
            path = local_file.sub(mapping["regexp"], mapping["path"])
          end
        end
      end
      if path.nil?
        if suffix == ".html"
          if @data.keys.find{|e| e.start_with?(uri + "/") }
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
      path = path.sub(param[:base_uri], "")
      path << suffix
      #p [uri, path]
      path
    end  

    def expand_rdf_list(data, head)
      elements = []
      while head && data[head]
        item = data[head]['http://www.w3.org/1999/02/22-rdf-syntax-ns#first']&.first
        elements << item if item
        head = data[head]['http://www.w3.org/1999/02/22-rdf-syntax-ns#rest']&.first
        break if head == 'http://www.w3.org/1999/02/22-rdf-syntax-ns#nil'
      end
      elements
    end
    
  end
end