module RubyLsp
  module Ree
    class Completion
      include Requests::Support::Common

      REE_PREFIX = '__ree_object_'
      
      def initialize(response_builder, node_context, index, dispatcher, uri)
        @response_builder = response_builder
        @index = index
        @uri = uri

        dispatcher.register(self, :on_call_node_enter)
      end

      def on_call_node_enter(node)
        return if node.receiver
        return if node.name.to_s.size < 5

        ree_objects = @index.prefix_search(REE_PREFIX + node.name.to_s).take(10)

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
            additional_text_edits: get_additional_text_edits(fn_name, package_name)
            # documentation: create_documentation(fn_name, params_str, ree_object, uri_parts)
          )
        end
        
        nil
      end

      def get_additional_text_edits(fn_name, package_name)
        ast = Prism.parse_file(@uri.path).value

        class_node = ast.statements.body.detect{ |node| node.is_a?(Prism::ClassNode) }
        fn_node = class_node.body.body.detect{ |node| node.name == :fn }
        block_node = fn_node.block

        return [] unless block_node # TODO handle no block
        # links = block_node.body.body.select{ |node| node.name == :link }
        
        fn_line = fn_node.location.start_line
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
    end
  end
end