module RubyLsp
  module Ree
    class LinkRenderer
      LINE_LENGTH = 80

      def render(link_node)
        offset = link_node.location.start_column
        offset_str = " " * offset

        if link_node.object_name_type?
          render_object_link(link_node, offset_str)
        elsif link_node.file_path_type?
          render_file_path_link(link_node, offset_str)
        elsif link_node.import_link_type?
          render_import_link(link_node, offset_str)
        else
          raise "unknown link type for render"
        end
      end

      private

      def render_object_link(link_node, offset_str)
        link_text = "#{offset_str}link "
        last_line = link_text

        link_node.linked_objects.each do |linked_object|
          linked_object_str = ":#{linked_object.name}"

          if last_line + ", #{linked_object_str}" <= LINE_LENGTH
            link_text += ", #{linked_object_str}"
          else
            link_text += ",\n#{offset_str}     #{linked_object_str}"
          end
          last_line = link_text.lines.last
        end

        if link_node.has_kwargs?
          kwargs_str = link_node.kw_args.elements.map{ "#{_1.key.unescaped}: :#{_1.value.unescaped}"}.join(', ')
          link_text += ", #{kwargs_str}"
        end

        link_text += "\n"
      end
    end
  end
end