module RubyLsp
  module Ree
    class Completion
      include Requests::Support::Common

      REE_PREFIX = '__ree_object_'
      CHARS_COUNT = 4
      
      def initialize(response_builder, node_context, index, dispatcher, uri)
        @response_builder = response_builder
        @index = index
        @uri = uri

        dispatcher.register(self, :on_call_node_enter)
      end

      def on_call_node_enter(node)
        return if node.receiver
        return if node.name.to_s.size < CHARS_COUNT

        ree_objects = @index.prefix_search(REE_PREFIX + node.name.to_s).take(10)

        return if ree_objects.size == 0

        doc_info = parse_doc_info()

        ree_objects.each do |ree_obj|
          ree_object = ree_obj.first

          fn_name = ree_object.name.delete_prefix(REE_PREFIX)

          uri_parts = ree_object.uri.to_s.split('/')
          package_index = uri_parts.find_index('package') + 1
          package_name = uri_parts[package_index]

          params_str = ree_object.signatures.first.parameters.map(&:name).join(', ')

          label_details = Interface::CompletionItemLabelDetails.new(
            description: "from: :#{package_name}",
            detail: "(#{params_str})"
          )

          @response_builder << Interface::CompletionItem.new(
            label: fn_name,
            label_details: label_details,
            filter_text: fn_name,
            text_edit: Interface::TextEdit.new(
              range:  range_from_location(node.location),
              new_text: "#{fn_name}(#{params_str})",
            ),
            kind: Constant::CompletionItemKind::METHOD,
            data: {
              owner_name: "Object",
              guessed_type: false,
            },
            additional_text_edits: get_additional_text_edits(doc_info, fn_name, package_name)
            # documentation: create_documentation(fn_name, params_str, ree_object, uri_parts)
          )
        end
        
        nil
      end

      def get_additional_text_edits(doc_info, fn_name, package_name)
        return [] unless doc_info.block_node # TODO handle no block
        
        if doc_info.linked_objects.map(&:name).include?(fn_name)
          $stderr.puts("links already include #{fn_name}")
          return []
        end

        fn_line = doc_info.fn_node.location.start_line
        position = 80 # TODO calc

        link_text = "\n\s\s\s\slink :#{fn_name}, from: :#{package_name}"

        range = Interface::Range.new(
          start: Interface::Position.new(line: fn_line - 1, character: position),
          end: Interface::Position.new(line: fn_line - 1, character: position + link_text.size),
        )

        $stderr.puts("===== get_additional_text_edits #{range.inspect}")

        [
          Interface::TextEdit.new(
            range:    range,
            new_text: link_text,
          )
        ]
      end

      def create_documentation(fn_name, params_str, ree_object, uri_parts)
        documentation = """
          ```ruby
          #{fn_name}(#{params_str})
          ```

          **Definitions**: [#{uri_parts.last}](#{ree_object.uri})

          :nodoc:
        """

        Interface::MarkupContent.new(kind: 'markdown', value: documentation)
      end

      def parse_doc_info
        ast = Prism.parse_file(@uri.path).value

        class_node = ast.statements.body.detect{ |node| node.is_a?(Prism::ClassNode) }
        fn_node = class_node.body.body.detect{ |node| node.name == :fn }
        block_node = fn_node.block

        link_nodes = if block_node
          block_node.body.body.select{ |node| node.name == :link }
        else
          []
        end

        linked_objects = link_nodes.map do |link_node|
          name_arg_node = link_node.arguments.arguments.first

          name_val = case name_arg_node
          when Prism::SymbolNode
            name_arg_node.value
          when Prism::StringNode
            name_arg_node.unescaped
          else
            ""
          end

          OpenStruct.new(
            name: name_val
          )
        end

        return OpenStruct.new(
          ast: ast,
          class_node: class_node,
          fn_node: fn_node,
          block_node: block_node,
          link_nodes: link_nodes,
          linked_objects: linked_objects
        )
      end
    end
  end
end