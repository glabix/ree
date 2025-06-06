module RubyLsp
  module Ree
    class ReeRenameHandler
      include RubyLsp::Ree::ReeLspUtils

      def self.call(changes)
        new.call(changes)
      end

      def call(changes)
        old_uri = URI.parse(changes.detect{ _1[:type] == Constant::FileChangeType::DELETED }[:uri])
        new_uri = URI.parse(changes.detect{ _1[:type] == Constant::FileChangeType::CREATED }[:uri])
      
        old_path = get_uri_path(old_uri)
        new_path = get_uri_path(new_uri)

        old_file_name = File.basename(old_path, '.rb').chomp(" copy")
        new_file_name = File.basename(new_path, '.rb')

        return if old_file_name == new_file_name

        parsed_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_uri(new_uri)

        return if !parsed_doc || !parsed_doc.class_node

        old_class_name = old_file_name.split('_').collect(&:capitalize).join
        new_class_name = new_file_name.split('_').collect(&:capitalize).join

        return unless parsed_doc.class_name == old_class_name

        file_content_lines = File.read(new_path).lines
        
        class_line = parsed_doc.class_node.location.start_line - 1

        file_content_lines[class_line].gsub!(/\b#{old_class_name}\b/, new_class_name)

        if parsed_doc.links_container_node
          links_container_node_line = parsed_doc.links_container_node.location.start_line - 1

          file_content_lines[links_container_node_line].gsub!(/\b#{old_file_name}\b/, new_file_name)
        end

        File.write(new_path, file_content_lines.join)
      end
    end
  end
end