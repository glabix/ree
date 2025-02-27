module RubyLsp
  module Ree
    module ReeLspUtils
      Entry = RubyIndexer::Entry

      def find_local_file_path(file_path)
        file_name = file_path + ".rb"
        Dir[File.join('**', file_name)].first
      end

      def package_name_from_uri(uri)
        uri_parts = uri.to_s.split('/')
        
        package_folder_index = uri_parts.find_index('package')
        return unless package_folder_index

        uri_parts[package_folder_index + 1]
      end

      def path_from_package_folder(uri)
        uri_parts = uri.to_s.chomp(File.extname(uri.to_s)).split('/')

        package_folder_index = uri_parts.index('package')
        return unless package_folder_index

        uri_parts.drop(package_folder_index+1).join('/')
      end

      def get_ree_type(ree_object)
        type_comment = ree_object.comments.to_s.lines[1]
        return unless type_comment

        type_comment.split(' ').last
      end

      def get_range_for_fn_insert(parsed_doc, link_text)
        fn_line = nil
        position = nil

        if parsed_doc.links_container_node
          links_container_node = parsed_doc.links_container_node
          fn_line = links_container_node.location.start_line

          position = if parsed_doc.links_container_block_node
            parsed_doc.links_container_block_node.opening_loc.end_column + 1
          else
            links_container_node.arguments.location.end_column + 1
          end
        elsif parsed_doc.includes_link_dsl?
          fn_line = parsed_doc.link_nodes.first.location.start_line - 1
          position = parsed_doc.link_nodes.first.location.start_column
        elsif parsed_doc.allows_root_links?
          root_node_location = parsed_doc.root_node_line_location
         
          fn_line = root_node_location.start_line
          position = root_node_location.end_column + 1
        else
          return nil
        end

        Interface::Range.new(
          start: Interface::Position.new(line: fn_line - 1, character: position),
          end: Interface::Position.new(line: fn_line - 1, character: position + link_text.size),
        )
      end


      # params(parameters_node: Prism::ParametersNode).returns(Array[Entry::Parameter])
      # copied from ruby-lsp DeclarationListener#list_params
      def signature_params_from_node(parameters_node)
        return [] unless parameters_node
  
        parameters = []
  
        parameters_node.requireds.each do |required|
          name = parameter_name(required)
          next unless name
  
          parameters << Entry::RequiredParameter.new(name: name)
        end
  
        parameters_node.optionals.each do |optional|
          name = parameter_name(optional)
          next unless name
  
          parameters << Entry::OptionalParameter.new(name: name)
        end
  
        rest = parameters_node.rest
  
        if rest.is_a?(Prism::RestParameterNode)
          rest_name = rest.name || Entry::RestParameter::DEFAULT_NAME
          parameters << Entry::RestParameter.new(name: rest_name)
        end
  
        parameters_node.keywords.each do |keyword|
          name = parameter_name(keyword)
          next unless name
  
          case keyword
          when Prism::RequiredKeywordParameterNode
            parameters << Entry::KeywordParameter.new(name: name)
          when Prism::OptionalKeywordParameterNode
            parameters << Entry::OptionalKeywordParameter.new(name: name)
          end
        end
  
        keyword_rest = parameters_node.keyword_rest
  
        case keyword_rest
        when Prism::KeywordRestParameterNode
          keyword_rest_name = parameter_name(keyword_rest) || Entry::KeywordRestParameter::DEFAULT_NAME
          parameters << Entry::KeywordRestParameter.new(name: keyword_rest_name)
        when Prism::ForwardingParameterNode
          parameters << Entry::ForwardingParameter.new
        end
  
        parameters_node.posts.each do |post|
          name = parameter_name(post)
          next unless name
  
          parameters << Entry::RequiredParameter.new(name: name)
        end
  
        block = parameters_node.block
        parameters << Entry::BlockParameter.new(name: block.name || Entry::BlockParameter::DEFAULT_NAME) if block
  
        parameters
      end

      # params(node: Prism::Node).returns(Symbol)
      # copied from ruby-lsp DeclarationListener#parameter_name
      def parameter_name(node)
        case node
        when Prism::RequiredParameterNode, Prism::OptionalParameterNode,
          Prism::RequiredKeywordParameterNode, Prism::OptionalKeywordParameterNode,
          Prism::RestParameterNode, Prism::KeywordRestParameterNode
          node.name
        when Prism::MultiTargetNode
          names = node.lefts.map { |parameter_node| parameter_name(parameter_node) }

          rest = node.rest
          if rest.is_a?(Prism::SplatNode)
            name = rest.expression&.slice
            names << (rest.operator == "*" ? "*#{name}".to_sym : name&.to_sym)
          end

          names << nil if rest.is_a?(Prism::ImplicitRestNode)

          names.concat(node.rights.map { |parameter_node| parameter_name(parameter_node) })

          names_with_commas = names.join(", ")
          :"(#{names_with_commas})"
        end
      end
    end
  end
end