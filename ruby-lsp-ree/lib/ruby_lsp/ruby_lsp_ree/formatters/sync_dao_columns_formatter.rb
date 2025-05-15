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

        missed_columns = parsed_doc.dao_fields - entity_doc.columns.map(&:name)
        add_columns(entity_path, entity_source, entity_doc, missed_columns)


        pp entities_folder
        pp entity_filename

        pp parsed_doc.dao_fields

        source
        
      end

      private 
      
      def add_columns(entity_path, entity_source, entity_doc, missed_columns)
        return if !missed_columns || missed_columns.size == 0

        source_lines = entity_source.lines


        File.write(entity_path, source_lines.join)
      end
    end
  end
end