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

        link_node.linked_objects.each_with_index do |linked_object, index|
          linked_object_str = ":#{linked_object.name}"
          last_line = link_text.lines.last

          if index == 0
            link_text += linked_object_str
            next
          end

          if (last_line + ", #{linked_object_str}").size <= LINE_LENGTH
            link_text += ", #{linked_object_str}"
          else
            link_text += ",\n#{offset_str}     #{linked_object_str}"
          end
        end

        link_text = render_kwargs(link_text, link_node, offset_str)

        link_text += "\n"
        link_text
      end

      def render_file_path_link(link_node, offset_str)
        link_text = "#{offset_str}link '#{link_node.name}', -> {"
        link_text = render_imports(link_text, link_node, offset_str)
       
        if link_node.has_kwargs?
          kwargs_str = link_node.kw_args.elements.map{ "#{_1.key.unescaped}: :#{_1.value.unescaped}"}.join(', ')
          link_text += ", #{kwargs_str}"
        end

        link_text += "\n"
        link_text
      end

      def render_import_link(link_node, offset_str)
        link_text = "#{offset_str}import -> {"
        link_text = render_imports(link_text, link_node, offset_str)

        if link_node.has_kwargs?
          kwargs_str = link_node.kw_args.elements.map{ "#{_1.key.unescaped}: :#{_1.value.unescaped}"}.join(', ')
          link_text += ", #{kwargs_str}"
        end

        link_text += "\n"
        link_text
      end

      def render_imports(link_text, link_node, offset_str)
        imports_str = link_node.import_items.map(&:to_s).join(' & ')

        if (link_text+imports_str).size < LINE_LENGTH
          link_text += " #{imports_str} }"
        else
          link_text += "\n"

          imports_str = "#{offset_str}  "
          last_line = imports_str
          link_node.import_items.each_with_index do |import_item, index|
            last_line = imports_str.lines.last

            if index == 0
              imports_str += import_item.to_s
              next
            end

            if (last_line + " & #{import_item.to_s}").size <= LINE_LENGTH
              imports_str += " & #{import_item.to_s}"
            else
              imports_str += " &\n#{offset_str}  #{import_item.to_s}"
            end
          end

          link_text += imports_str
          link_text += "\n#{offset_str}}"
        end

        link_text
      end

      def render_kwargs(link_text, link_node, offset_str)
        return link_text unless link_node.has_kwargs?
          
        if link_node.object_name_type? && link_node.has_import_section?
          link_text += ", import: -> {"          
          link_text = render_imports(link_text, link_node, offset_str)
        end

        kwargs_str = link_node.kw_args.elements.reject{ _1.key.unescaped == 'import' }.map{ "#{_1.key.unescaped}: #{value_name(_1)}"}.join(', ')
        link_text += ", #{kwargs_str}" if kwargs_str.size > 0

        link_text
      end

      def value_name(elem)
        if elem.value.respond_to?(:unescaped)
         ":#{elem.value.unescaped}"
        else
          elem.value.name.to_s
        end
      end
    end
  end
end