module RubyLsp
  module Ree
    class MethodAdditionalTextEditsCreator
      include RubyLsp::Ree::ReeLspUtils

      def self.call(parsed_doc, ree_object_name, package_name)
        new(parsed_doc, ree_object_name, package_name).call
      end

      def initialize(parsed_doc, ree_object_name, package_name)
        @parsed_doc = parsed_doc
        @ree_object_name = ree_object_name
        @package_name = package_name
      end

      def call
        return [] unless @parsed_doc

        if @parsed_doc.includes_linked_object?(@ree_object_name)
          return []
        end

        link_text = if @parsed_doc.package_name == @package_name
          "\s\slink :#{@ree_object_name}"
        else
          "\s\slink :#{@ree_object_name}, from: :#{@package_name}"
        end

        if @parsed_doc.links_container_node
          link_text = "\s\s" + link_text
        end
        
        new_text = "\n" + link_text

        if @parsed_doc.has_blank_links_container?
          new_text = "\sdo#{new_text}\n\s\send\n"
        end

        range = get_range_for_fn_insert(@parsed_doc, link_text)
        return unless range

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
