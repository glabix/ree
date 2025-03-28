module RubyLsp
  module Ree
    class ConstAdditionalTextEditsCreator
      include RubyLsp::Ree::ReeLspUtils

      def self.call(parsed_doc, const_name, package_name, entry)
        new(parsed_doc, const_name, package_name, entry).call
      end

      def initialize(parsed_doc, const_name, package_name, entry)
        @parsed_doc = parsed_doc
        @const_name = const_name
        @package_name = package_name
        @entry = entry
      end

      def call
        if @parsed_doc.includes_linked_constant?(@const_name)
          return []
        end

        const_link = get_constant_link

        if existing_link = @parsed_doc.find_link_node(const_link[:object_name])
          # attach to existing link
          if existing_link.has_import_section?
            new_text = "& #{@const_name} }"
            position = existing_link.location.end_column
            range = Interface::Range.new(
              start: Interface::Position.new(line: existing_link.location.start_line-1, character: position),
              end: Interface::Position.new(line: existing_link.location.start_line-1, character: position + new_text.size),
            )
          else
            if existing_link.object_name_type?
              new_text = ", import: -> { #{@const_name} }"
            else
              new_text = ", -> { #{@const_name} }"
            end

            position = existing_link.location.end_column + 1
            range = Interface::Range.new(
              start: Interface::Position.new(line: existing_link.location.start_line-1, character: position),
              end: Interface::Position.new(line: existing_link.location.start_line-1, character: position + new_text.size),
            )
          end          
        else
          # add new link

          link_text = "\s\slink #{const_link[:link_name]}, import: -> { #{@const_name} }"

          if @parsed_doc.links_container_node
            link_text = "\s\s" + link_text
          end

          new_text = "\n" + link_text

          if @parsed_doc.has_blank_links_container?
            new_text = "\sdo#{link_text}\n\s\send\n"
          end

          range = get_range_for_fn_insert(@parsed_doc, link_text)
        end

        [
          Interface::TextEdit.new(
            range:    range,
            new_text: new_text,
          )
        ]
      end

      private

      def is_ree_object?(uri)
        doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_uri(uri)
        return false unless doc.has_root_class?
        
        doc.parse_links_container_node
        return !!doc.links_container_node
      end

      def get_constant_link
        entry_uri = @entry.uri.to_s
        
        ree_obj_name = nil
        link_name = nil

        if is_ree_object?(@entry.uri)
          ree_obj_name = File.basename(entry_uri, ".*")
          link_name = ":#{ree_obj_name}"

          if @package_name != @parsed_doc.package_name
            link_name += ", from: :#{@package_name}"
          end
        else
          ree_obj_name = path_from_package_folder(entry_uri)
          link_name = "\"#{ree_obj_name}\""
        end

        return { link_name: link_name, object_name: ree_obj_name }
      end
    end
  end
end
