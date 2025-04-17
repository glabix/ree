require_relative 'method_additional_text_edits_creator'
require_relative 'const_additional_text_edits_creator'

module RubyLsp
  module Ree
    class CompletionItemsMapper
      include Requests::Support::Common
      include RubyLsp::Ree::ReeLspUtils

      def initialize(index)
        @index = index
      end

      def map_ree_object_methods(ree_object_methods, location, node, description)
        default_range = Interface::Range.new(
          start: Interface::Position.new(line: location.start_line - 1, character: location.end_column + 1),
          end: Interface::Position.new(line: location.start_line - 1, character: location.end_column + 1),
        )

        ree_object_methods.map do |object_method|
          signature = object_method.signatures&.first

          label_details = Interface::CompletionItemLabelDetails.new(
            description: description,
            detail: get_detail_string(signature)
          )

          if node.arguments && node.name.to_s == object_method.name
            new_text = object_method.name
            method_range = range_from_location(node.message_loc)
          else
            new_text = get_method_string(object_method.name, signature)
            method_range = default_range
          end

          Interface::CompletionItem.new(
            label: object_method.name,
            label_details: label_details,
            filter_text: object_method.name,
            text_edit: Interface::TextEdit.new(
              range:  method_range,
              new_text: new_text
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

      def map_ree_objects(ree_objects, node, parsed_doc)
        ree_objects.map do |ree_object|
          ree_object_name = ree_object.name
          package_name = package_name_from_uri(ree_object.uri)
          signature = ree_object.signatures.first
          ree_type = get_ree_type(ree_object)

          label_details = Interface::CompletionItemLabelDetails.new(
            description: "#{ree_type}, from: :#{package_name}",
            detail: get_detail_string(signature)
          )

          if node.arguments && node.name.to_s == ree_object_name
            new_text = ree_object_name
            range = range_from_location(node.message_loc)
          else
            new_text = get_method_string(ree_object_name, signature)
            range = range_from_location(node.location)
          end

          Interface::CompletionItem.new(
            label: ree_object_name,
            label_details: label_details,
            filter_text: ree_object_name,
            text_edit: Interface::TextEdit.new(
              range:  range,
              new_text: new_text
            ),
            kind: Constant::CompletionItemKind::METHOD,
            insert_text_format: Constant::InsertTextFormat::SNIPPET,
            data: {
              owner_name: "Object",
              guessed_type: false,
            },
            additional_text_edits: MethodAdditionalTextEditsCreator.call(parsed_doc, ree_object_name, package_name)
          )
        end
      end

      def map_class_name_objects(class_name_objects, node, parsed_doc)
        imported_consts = []
        not_imported_consts = []

        class_name_objects.each do |full_class_name|
          entries = @index[full_class_name]

          entries.each do |entry|
            class_name = full_class_name.split('::').last
            package_name = package_name_from_uri(entry.uri)
            file_name = File.basename(entry.uri.to_s)
            entry_comment = entry.comments && entry.comments.size > 0 ? " (#{entry.comments})" : ''

            matched_import = parsed_doc.find_import_for_package(class_name, package_name)

            if matched_import   
              label_details = Interface::CompletionItemLabelDetails.new(
                description: "imported from: :#{package_name}",
                detail: entry_comment
              )
              
              imported_consts << Interface::CompletionItem.new(
                label: class_name,
                label_details: label_details,
                filter_text: class_name,
                text_edit: Interface::TextEdit.new(
                  range:  range_from_location(node.location),
                  new_text: class_name,
                ),
                kind: Constant::CompletionItemKind::CLASS,
                additional_text_edits: []
              )
            else
              label_details = Interface::CompletionItemLabelDetails.new(
                description: "from: :#{package_name}",
                detail: entry_comment + " #{file_name}"
              )

              not_imported_consts << Interface::CompletionItem.new(
                label: class_name,
                label_details: label_details,
                filter_text: class_name,
                text_edit: Interface::TextEdit.new(
                  range:  range_from_location(node.location),
                  new_text: class_name,
                ),
                kind: Constant::CompletionItemKind::CLASS,
                additional_text_edits: ConstAdditionalTextEditsCreator.call(parsed_doc, class_name, package_name, entry)
              )
            end
          end
        end

        imported_consts + not_imported_consts
      end

      private

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
    end
  end
end
