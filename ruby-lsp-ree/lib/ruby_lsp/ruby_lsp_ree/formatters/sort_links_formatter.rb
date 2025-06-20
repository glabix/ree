require_relative 'base_formatter'
require_relative '../ree_source_editor'
require_relative '../renderers/link_renderer'

module RubyLsp
  module Ree
    class SortLinksFormatter < BaseFormatter
      def call(source, _uri)
        parsed_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_source(source)
        return source if !parsed_doc || !parsed_doc.link_nodes&.any?

        # Order of groups:
        # - links from the current package without options
        # - links from the current package with options
        # - links from other packages
        # - links with filenames
        # - import links

        editor = RubyLsp::Ree::ReeSourceEditor.new(source)
        renderer = RubyLsp::Ree::LinkRenderer.new
        # cleanup old links
        parsed_doc.link_nodes.each do |link_node|
          editor.remove_link(link_node)
        end
        editor.cleanup_blank_lines(parsed_doc.link_nodes.first.location.start_line-1, parsed_doc.link_nodes.last.location.end_line-1)

        link_groups = [
          parsed_doc.link_nodes.select(&:object_name_type?).select{ !_1.has_kwargs? },
          parsed_doc.link_nodes.select(&:object_name_type?).select(&:has_kwargs?).select{ !_1.from_arg_value },
          parsed_doc.link_nodes.select(&:object_name_type?).select{ !!_1.from_arg_value },
          parsed_doc.link_nodes.select(&:file_path_type?),
          parsed_doc.link_nodes.select(&:import_link_type?),
        ]

        link_groups_texts = link_groups.map do |link_group|
          link_group.map{ renderer.render(_1) }.join('')
        end

        editor.insert_link_block(parsed_doc, link_groups_texts.select{ _1.size > 0 }.join("\n"))
        editor.source
      end
    end
  end
end