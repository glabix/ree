require_relative "ree_lsp_utils"

module RubyLsp
  module Ree
    class Completion
      include Requests::Support::Common
      include RubyLsp::Ree::ReeLspUtils

      CHARS_COUNT = 4
      
      def initialize(response_builder, node_context, index, dispatcher, uri)
        @response_builder = response_builder
        @index = index
        @uri = uri

        dispatcher.register(self, :on_call_node_enter)
        dispatcher.register(self, :on_constant_read_node_enter)
      end

      def on_constant_read_node_enter(node)
        node_name = node.name.to_s
        return if node_name.size < CHARS_COUNT

        class_name_objects = @index.instance_variable_get(:@entries).keys.select{ _1.split('::').last[0...node_name.size] == node_name}
        return if class_name_objects.size == 0

        doc_info = parse_document_from_uri(@uri)

        class_name_objects.take(15).each do |full_class_name|
          entry = @index[full_class_name].first
          class_name = full_class_name.split('::').last

          package_name = package_name_from_uri(entry.uri)

          label_details = Interface::CompletionItemLabelDetails.new(
            description: "from: :#{package_name}",
            detail: ""
          )

          @response_builder << Interface::CompletionItem.new(
            label: class_name,
            label_details: label_details,
            filter_text: class_name,
            text_edit: Interface::TextEdit.new(
              range:  range_from_location(node.location),
              new_text: class_name,
            ),
            kind: Constant::CompletionItemKind::CLASS,
            additional_text_edits: get_additional_text_edits_for_constant(doc_info, class_name, package_name, entry)
          )
        end

        nil
      end

      def on_call_node_enter(node)
        return if node.receiver
        return if node.name.to_s.size < CHARS_COUNT

        ree_objects = @index.prefix_search(node.name.to_s)
          .take(50).map(&:first)
          .select{ _1.comments }
          .select{ _1.comments.to_s.lines.first&.chomp == 'ree_object' }
          .take(10)

        return if ree_objects.size == 0

        doc_info = parse_document_from_uri(@uri)

        ree_objects.each do |ree_object|
          fn_name = ree_object.name

          package_name = package_name_from_uri(ree_object.uri)

          params_str = ree_object.signatures.first.parameters.map(&:name).join(', ')

          label_details = Interface::CompletionItemLabelDetails.new(
            description: "from: :#{package_name}",
            detail: "(#{params_str})"
          )

          $stderr.puts("ree object #{ree_object.inspect}")

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
            additional_text_edits: get_additional_text_edits_for_method(doc_info, fn_name, package_name)
          )
        end
        
        nil
      end

      def get_additional_text_edits_for_constant(doc_info, class_name, package_name, entry)
        if doc_info.linked_objects.map(&:imports).flatten.include?(class_name)
          $stderr.puts("links already include #{class_name}")
          return []
        end

        entry_uri = entry.uri.to_s

        link_text = if doc_info.package_name == package_name
          fn_name = File.basename(entry_uri, ".*")
          "\n\s\s\s\slink :#{fn_name}, import: -> { #{class_name} }"
        else
          path = path_from_package(entry_uri)
          "\n\s\s\s\slink \"#{path}\", import: -> { #{class_name} }"
        end

        new_text = link_text

        unless doc_info.block_node
          new_text = "\sdo#{link_text}\n\s\send\n"
        end

        range = get_range_for_fn_insert(doc_info, link_text)

        [
          Interface::TextEdit.new(
            range:    range,
            new_text: new_text,
          )
        ]
      end

      def get_additional_text_edits_for_method(doc_info, fn_name, package_name)
        if doc_info.linked_objects.map(&:name).include?(fn_name)
          $stderr.puts("links already include #{fn_name}")
          return []
        end

        link_text = if doc_info.package_name == package_name
          "\n\s\s\s\slink :#{fn_name}"
        else
          "\n\s\s\s\slink :#{fn_name}, from: :#{package_name}"
        end
        
        new_text = link_text

        unless doc_info.block_node
          new_text = "\sdo#{link_text}\n\s\send\n"
        end

        range = get_range_for_fn_insert(doc_info, link_text)

        [
          Interface::TextEdit.new(
            range:    range,
            new_text: new_text,
          )
        ]
      end
    end
  end
end