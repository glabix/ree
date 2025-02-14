require_relative "ree_lsp_utils"

module RubyLsp
  module Ree
    module CompletionUtils
      include Requests::Support::Common
      include RubyLsp::Ree::ReeLspUtils

      def get_bean_methods_completion_items(bean_obj, location)
        bean_node = RubyLsp::Ree::ParsedDocumentBuilder.build_from_uri(bean_obj.uri, :bean)
        
        range = Interface::Range.new(
          start: Interface::Position.new(line: location.start_line - 1, character: location.end_column + 1),
          end: Interface::Position.new(line: location.start_line - 1, character: location.end_column + 1),
        )

        bean_node.bean_methods.map do |bean_method|
          signature = bean_method.signatures.first

          label_details = Interface::CompletionItemLabelDetails.new(
            description: "method",
            detail: get_detail_string(signature)
          )

          Interface::CompletionItem.new(
            label: bean_method.name,
            label_details: label_details,
            filter_text: bean_method.name,
            text_edit: Interface::TextEdit.new(
              range:  range,
              new_text: get_method_string(bean_method.name, signature)
            ),
            kind: Constant::CompletionItemKind::METHOD,
            insert_text_format: Constant::InsertTextFormat::SNIPPET,
            data: {
              owner_name: "Object",
              guessed_type: false,
            }
          )
        end
      end

      def get_dao_filters_completion_items(dao_obj, location)
        dao_node = RubyLsp::Ree::ParsedDocumentBuilder.build_from_uri(dao_obj.uri, :dao)
        
        range = Interface::Range.new(
          start: Interface::Position.new(line: location.start_line - 1, character: location.end_column + 1),
          end: Interface::Position.new(line: location.start_line - 1, character: location.end_column + 1),
        )

        dao_node.filters.map do |filter|
          signature = filter.signatures.first

          label_details = Interface::CompletionItemLabelDetails.new(
            description: "filter",
            detail: get_detail_string(signature)
          )

          Interface::CompletionItem.new(
            label: filter.name,
            label_details: label_details,
            filter_text: filter.name,
            text_edit: Interface::TextEdit.new(
              range:  range,
              new_text: get_method_string(filter.name, signature)
            ),
            kind: Constant::CompletionItemKind::METHOD,
            insert_text_format: Constant::InsertTextFormat::SNIPPET,
            data: {
              owner_name: "Object",
              guessed_type: false,
            }
          )
        end
      end

      def get_enum_values_completion_items(enum_obj, location)
        enum_node = RubyLsp::Ree::ParsedDocumentBuilder.build_from_uri(enum_obj.uri, :enum)

        class_name = enum_node.get_class_name

        label_details = Interface::CompletionItemLabelDetails.new(
          description: "from: #{class_name}",
          detail: ''
        )

        range = Interface::Range.new(
          start: Interface::Position.new(line: location.start_line - 1, character: location.end_column + 1),
          end: Interface::Position.new(line: location.start_line - 1, character: location.end_column + 1),
        )

        enum_node.values.map do |val|
          Interface::CompletionItem.new(
            label: val.name,
            label_details: label_details,
            filter_text: val.name,
            text_edit: Interface::TextEdit.new(
              range:  range,
              new_text: val.name
            ),
            kind: Constant::CompletionItemKind::METHOD,
            data: {
              owner_name: "Object",
              guessed_type: false,
            }
          )
        end
      end

      def get_class_name_completion_items(class_name_objects, parsed_doc, node, index, limit)
        class_name_objects.take(limit).map do |full_class_name|
          entry = index[full_class_name].first
          class_name = full_class_name.split('::').last

          package_name = package_name_from_uri(entry.uri)
          file_name = File.basename(entry.uri.to_s)
          
          label_details = Interface::CompletionItemLabelDetails.new(
            description: "from: :#{package_name}",
            detail: " #{file_name}"
          )

          Interface::CompletionItem.new(
            label: class_name,
            label_details: label_details,
            filter_text: class_name,
            text_edit: Interface::TextEdit.new(
              range:  range_from_location(node.location),
              new_text: class_name,
            ),
            kind: Constant::CompletionItemKind::CLASS,
            additional_text_edits: get_additional_text_edits_for_constant(parsed_doc, class_name, package_name, entry)
          )
        end
      end

      def get_ree_objects_completions_items(ree_objects, parsed_doc, node)
        ree_objects.map do |ree_object|
          ree_object_name = ree_object.name
          package_name = package_name_from_uri(ree_object.uri)
          signature = ree_object.signatures.first
          ree_type = get_ree_type(ree_object)

          label_details = Interface::CompletionItemLabelDetails.new(
            description: "#{ree_type}, from: :#{package_name}",
            detail: get_detail_string(signature)
          )

          Interface::CompletionItem.new(
            label: ree_object_name,
            label_details: label_details,
            filter_text: ree_object_name,
            text_edit: Interface::TextEdit.new(
              range:  range_from_location(node.location),
              new_text: get_method_string(ree_object_name, signature)
            ),
            kind: Constant::CompletionItemKind::METHOD,
            insert_text_format: Constant::InsertTextFormat::SNIPPET,
            data: {
              owner_name: "Object",
              guessed_type: false,
            },
            additional_text_edits: get_additional_text_edits_for_method(parsed_doc, ree_object_name, package_name)
          )
        end
      end

      def get_detail_string(signature)
        return '' unless signature

        "(#{get_parameters_string(signature)})"
      end

      def get_parameters_string(signature)
        return '' unless signature

        signature.parameters.map(&:decorated_name).join(', ')
      end

      def get_method_string(fn_name, signature)
        return fn_name unless signature
        
        "#{fn_name}(#{get_parameters_placeholder(signature)})"
      end

      def get_parameters_placeholder(signature)
        return '' unless signature

        signature.parameters.to_enum.with_index.map do |signature_param, index|
          case signature_param          
          when RubyIndexer::Entry::KeywordParameter, RubyIndexer::Entry::OptionalKeywordParameter
            "#{signature_param.name}: ${#{index+1}:#{signature_param.name}}"
          else
            "${#{index+1}:#{signature_param.name}}"
          end
        end.join(', ')
      end

      def get_additional_text_edits_for_constant(parsed_doc, class_name, package_name, entry)
        if parsed_doc.includes_linked_constant?(class_name)
          return []
        end

        entry_uri = entry.uri.to_s

        link_text = if parsed_doc.package_name == package_name
          fn_name = File.basename(entry_uri, ".*")
          "\s\slink :#{fn_name}, import: -> { #{class_name} }"
        else
          path = path_from_package_folder(entry_uri)
          "\s\slink \"#{path}\", import: -> { #{class_name} }"
        end

        if parsed_doc.links_container_node
          link_text = "\s\s" + link_text
        end
        
        new_text = "\n" + link_text


        if parsed_doc.has_blank_links_container?
          new_text = "\sdo#{link_text}\n\s\send\n"
        end

        range = get_range_for_fn_insert(parsed_doc, link_text)

        [
          Interface::TextEdit.new(
            range:    range,
            new_text: new_text,
          )
        ]
      end

      def get_additional_text_edits_for_method(parsed_doc, fn_name, package_name)
        if parsed_doc.includes_linked_object?(fn_name)
          return []
        end

        link_text = if parsed_doc.package_name == package_name
          "\s\slink :#{fn_name}"
        else
          "\s\slink :#{fn_name}, from: :#{package_name}"
        end

        if parsed_doc.links_container_node
          link_text = "\s\s" + link_text
        end
        
        new_text = "\n" + link_text

        if parsed_doc.has_blank_links_container?
          new_text = "\sdo#{link_text}\n\s\send\n"
        end

        range = get_range_for_fn_insert(parsed_doc, link_text)

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