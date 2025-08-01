module RubyLsp
  module Ree
    class ReeSourceEditor
      include RubyLsp::Ree::ReeLspUtils

      attr_reader :source_lines

      def initialize(source)
        @source_lines = source.lines
      end

      def source
        @source_lines.join
      end

      def contains_linked_object_usage?(parsed_doc, link_node, linked_object)
        if parsed_doc.respond_to?(:parse_method_calls)
          method_calls = parsed_doc.parse_method_calls
          no_receiver_method_names = method_calls.reject(&:has_receiver?).map(&:name).map(&:to_s)
          return no_receiver_method_names.include?(linked_object.usage_name)
        end

        source_lines_except_link = source_lines[0...(link_node.location.start_line-1)] + source_lines[(link_node.location.end_line)..-1]
        source_lines_except_link.any?{ |source_line| source_line.match?(/\W#{linked_object.usage_name}\W/)}
      end

      def contains_link_import_usage?(parsed_doc, link_node, link_import)
        if parsed_doc.respond_to?(:parse_const_objects)
          const_objects = parsed_doc.parse_const_objects
          return const_objects.map(&:name).map(&:to_s).include?(link_import)
        end

        source_lines_except_link = source_lines[0...(link_node.location.start_line-1)] + source_lines[(link_node.location.end_line)..-1]
        source_lines_except_link.any?{ |source_line| source_line.match?(/\W#{link_import}\W/)}
      end

      def remove_link(link_node)
        set_empty_lines_for_location!(link_node.location)
      end

      def remove_linked_objects(link_node, linked_objects)
        return if linked_objects.size == 0

        if link_node.multi_object_link?
          set_empty_lines_for_location!(link_node.location)
          line = link_node.location.start_line - 1
          offset = link_node.location.start_column - 1
          offset_str = " " * offset
          # TODO use renderer class
          linked_object_names = linked_objects.map(&:name)
          remaining_objects = link_node.linked_objects.select{ !linked_object_names.include?(_1.name) }
          source_lines[line] = "#{offset_str}link #{remaining_objects.map{ ":#{_1.name}" }.join(', ')}"
          if link_node.from_arg_value
            source_lines[line] += ", from: :#{link_node.from_arg_value}"
          end
          source_lines[line] += "\n"
        else
          set_empty_lines_for_location!(link_node.location)
        end
      end

      def remove_link_imports(link_node, link_imports)
        return if link_imports.size == 0
        imports_str = link_node.import_items.reject{ link_imports.include?(_1.name) }.map(&:to_s).join(' & ')

        block_start_col = link_node.import_block_open_location.start_column
        block_line = link_node.import_block_open_location.start_line-1
        block_end_line = link_node.import_block_close_location.end_line-1
        block_end_col = link_node.import_block_close_location.end_column
        # TODO use renderer class

        source_lines[block_line] = source_lines[block_line][0..block_start_col] + " #{imports_str} }" + source_lines[block_end_line][block_end_col..-1]
        set_empty_lines!(block_line+1, block_end_line)
      end

      def remove_link_import_arg(link_node)
        link_line = link_node.location.start_line - 1
        link_end_line = link_node.location.end_line - 1
        link_name_end = link_node.first_arg_location.end_column - 1

        source_lines[link_line] = source_lines[link_line][0..link_name_end] + "\n"
        set_empty_lines!(link_line+1, link_end_line)
      end

      def remove_link_block(links_container_node, links_container_block_node)
        return source_lines unless links_container_block_node
        
        link_container_start_line = links_container_node.location.start_line-1
        link_container_end_line = links_container_node.location.end_line-1
        block_start = links_container_block_node.location.start_column-1

        source_lines[link_container_start_line] = source_lines[link_container_start_line][0..block_start] + "\n"
        set_empty_lines!(link_container_start_line+1, link_container_end_line)
      end

      def remove_dao_field(field)
        set_empty_lines_for_location!(field.location)
      end

      def cleanup_blank_lines(start_line, end_line)
        (start_line .. end_line).each do |i|
          source_lines[i] = '' if source_lines[i].strip == ''
        end
      end

      def insert_link_block(parsed_doc, links_text)
        line = if parsed_doc.links_container_node
          parsed_doc.links_container_node.location.start_line
        else
          parsed_doc.link_nodes.first.location.start_line - 1
        end

        source_lines[line] = links_text
      end

      def add_links(parsed_doc, ree_objects, current_package)
        new_text = ''

        ree_objects.each do |ree_object|
          link_text = if current_package == ree_object.object_package
            "\s\slink :#{ree_object.name}"
          else
            package_str = ree_object.object_package == 'FILL_PACKAGE' ? 'FILL_PACKAGE' : ":#{ree_object.object_package}"
            "\s\slink :#{ree_object.name}, from: #{package_str}"
          end

          if parsed_doc.links_container_node
            link_text = "\s\s" + link_text
          end
        
          new_text += "\n" + link_text
        end

        new_text += "\n"

        if parsed_doc.has_blank_links_container?
          new_text = "\sdo#{new_text}\s\send\n"
        end

        if parsed_doc.links_container_node
          line = parsed_doc.links_container_node.location.start_line - 1
          source_lines[line] = source_lines[line].chomp + new_text
        elsif parsed_doc.link_nodes.size > 0
          line = parsed_doc.link_nodes.last.location.end_line - 1
          source_lines[line] = source_lines[line].chomp + new_text
        else
          line = parsed_doc.class_includes.last.location.end_line - 1
          source_lines[line] = source_lines[line].chomp + "\n" + new_text
        end
      end

      def change_link_package(link_node, new_package, current_package)
        if new_package == current_package # change package to current -> remove 'from' param
          return unless link_node.from_param

          from_param_location = link_node.from_param.location
          name_location = link_node.first_arg_location

          line = from_param_location.start_line - 1
          start_column = name_location.end_column - 1
          end_column = from_param_location.end_column

          source_lines[line] = source_lines[line][0..start_column] + source_lines[line][end_column..-1]
        elsif link_node.from_param
          from_param_location = link_node.from_param.value.location
          line = from_param_location.start_line - 1
          start_column = from_param_location.start_column - 1
          end_column = from_param_location.end_column

          source_lines[line] = source_lines[line][0..start_column] + ":#{new_package}" + source_lines[line][end_column..-1]
        else
          name_location = link_node.first_arg_location
          line = name_location.start_line - 1
          start_column = name_location.end_column - 1

          source_lines[line] = source_lines[line][0..start_column] + ", from: :#{new_package}" + source_lines[line][start_column+1..-1]
        end
      end

      private

      def set_empty_lines_for_location!(location)
        set_empty_lines!(location.start_line-1, location.end_line-1)
      end

      def set_empty_lines!(start_line, end_line)
        (start_line .. end_line).each do |i|
          source_lines[i] = ''
        end
      end
    end
  end
end