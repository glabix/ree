module RubyLsp
  module Ree
    module ReeLspUtils
      def package_name_from_uri(uri)
        uri_parts = uri.to_s.split('/')
        package_index = uri_parts.find_index('package') + 1
        uri_parts[package_index]
      end

      def path_from_package(uri)
        uri_parts = uri.chomp(File.extname(uri)).split('/')
        pack_folder_index = uri_parts.index('package')
        uri_parts.drop(pack_folder_index+1).join('/')
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
        end

        Interface::Range.new(
          start: Interface::Position.new(line: fn_line - 1, character: position),
          end: Interface::Position.new(line: fn_line - 1, character: position + link_text.size),
        )
      end
    end
  end
end