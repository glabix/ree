require_relative 'base_formatter'

module RubyLsp
  module Ree
    class SyncDaoColumnsFormatter < BaseFormatter
      include RubyLsp::Ree::ReeLspUtils

      def call(source, uri)
        path = uri.path.to_s
        path_parts = path.split('/')
        return source unless path_parts.include?('dao')
        
        parsed_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_source(source, type: :dao)
        return source if !parsed_doc
        
        parsed_doc.parse_class_includes
        return unless parsed_doc.includes_dao_dsl?

        dao_folder_index = path_parts.index('dao')
        entities_folder = path_parts.take(dao_folder_index).join('/') + '/entities'

        dao_filename = File.basename(path, '.rb')
  
        if dao_filename.end_with?('ies')
          entity_filename = dao_filename[0..-4] + 'y'
        elsif dao_filename.end_with?('es')
          entity_filename = dao_filename[0..-3]
        else
          entity_filename = dao_filename[0..-2]
        end

        entity_filename = entity_filename + '.rb'

        entity_paths = Dir[File.join(entities_folder, '**', entity_filename)]
        if entity_paths.size > 1
          $stderr.puts("multiple entity paths for #{path}")
          return source
        elsif entity_paths.size == 0
          $stderr.puts("no entity paths #{path}")
          return source
        end

        entity_path = entity_paths.first
        entity_source = File.read(entity_path)
        entity_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_source(entity_source, type: :entity)

        missed_column_names = parsed_doc.dao_fields.map(&:name) - entity_doc.columns.map(&:name)
        missed_columns = parsed_doc.dao_fields.select{ missed_column_names.include?(_1.name) }
        add_columns(entity_path, entity_source, entity_doc, missed_columns)


        # pp entities_folder
        # pp entity_filename

        # pp parsed_doc.dao_fields

        source
        
      end

      private 
      
      def add_columns(entity_path, entity_source, entity_doc, missed_columns)
        puts "add columns"
        pp missed_columns
        return if !missed_columns || missed_columns.size == 0

        columns_strs = missed_columns.map do |col|
          str = "    column :#{col.name}, #{col.type}"
          if col.has_default?
            str += ", default: #{col.default}"
          end
          str
        end

        columns_str = columns_strs.join("\n") + "\n"

        source_lines = entity_source.lines

        prev_line_location = if entity_doc.columns.size > 0
          entity_doc.columns.last.location
        else
          entity_doc.build_dto_node.location
        end

        line = prev_line_location.start_line - 1

        source_lines[line] += columns_str

        File.write(entity_path, source_lines.join)
      end
    end
  end
end