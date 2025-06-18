require_relative "../utils/ree_lsp_utils"
require_relative "../ree_object_finder"
require_relative "../parsing/parsed_link_node"
require_relative "../parsing/parsed_link_node_builder"
require_relative "../parsing/parsed_document_builder"
require_relative "../utils/ree_locale_utils"

module RubyLsp
  module Ree
    class DefinitionHandler
      include Requests::Support::Common
      include RubyLsp::Ree::ReeLspUtils
      include RubyLsp::Ree::ReeLocaleUtils

      def initialize(index, uri, node_context)
        @index = index
        @uri = uri
        @node_context = node_context
        @root_node = @node_context.instance_variable_get(:@nesting_nodes).first
        @finder = ReeObjectFinder.new(@index)
      end

      def get_constant_definition_items(node)
        result = []

        link_nodes = if @node_context.parent.is_a?(Prism::CallNode) && @node_context.parent.name == :link
          # inside link node
          link_node = RubyLsp::Ree::ParsedLinkNodeBuilder.build_from_node(@node_context.parent, nil)
          [link_node]
        else
          parsed_doc = if @node_context.parent.is_a?(Prism::CallNode)
            RubyLsp::Ree::ParsedDocumentBuilder.build_from_uri(@uri)
          else
            RubyLsp::Ree::ParsedDocumentBuilder.build_from_ast(@node_context.parent, @uri)
          end

          parsed_doc.link_nodes
        end
        
        link_nodes.each do |link_node|
          if link_node.imports.include?(node.name.to_s)
            uri = ''
            if link_node.file_path_type?
              path = find_local_file_path(link_node.name)  
              next unless path

              uri = File.join(Dir.pwd, path)
            else
              package_name = link_node.link_package_name || package_name_from_uri(@uri)

              method_candidates = @index[link_node.name]
              next if !method_candidates || method_candidates.size == 0
        
              method = method_candidates.detect{ package_name_from_uri(_1.uri) == package_name }
              next unless method

              uri = method.uri.to_s
            end

            result << Interface::Location.new(
              uri: uri,
              range: Interface::Range.new(
                start: Interface::Position.new(line: 0, character: 0),
                end: Interface::Position.new(line: 0, character: 0),
              ),
            )
          end
        end

        result
      end

      def get_ree_objects_definition_items(node)
        message = node.message
        result = []
        
        parsed_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_ast(@root_node, @uri)
        link_node = parsed_doc.find_link_by_usage_name(message)

        definition_item = if link_node
          @finder.find_object_for_package(link_node.name, link_node.link_package_name)
        else
          @finder.find_object(message)
        end

        return [] unless definition_item

        definition_uri = definition_item.uri.to_s
        return [] unless definition_uri

        result << Interface::Location.new(
          uri: definition_uri,
          range: Interface::Range.new(
            start: Interface::Position.new(line: 0, character: 0),
            end: Interface::Position.new(line: 0, character: 0),
          ),
        )

        result
      end

      def get_linked_object_definition_items(node)
        result = []
        parent_node = @node_context.parent

        link_node = RubyLsp::Ree::ParsedLinkNodeBuilder.build_from_node(parent_node, package_name_from_uri(@uri))
        package_name = link_node.link_package_name

        method_candidates = @index[link_node.name]
        return [] if !method_candidates || method_candidates.size == 0
        
        method = method_candidates.detect{ package_name_from_uri(_1.uri) == package_name }
        return [] unless method

        result << Interface::Location.new(
          uri: method.uri.to_s,
          range: Interface::Range.new(
            start: Interface::Position.new(line: 0, character: 0),
            end: Interface::Position.new(line: 0, character: 0),
          ),
        )

        result
      end

      def get_routes_definition_items(node)
        parsed_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_ast(@root_node, @uri, :route)

        return [] unless parsed_doc.includes_routes_dsl?

        parent_node = @node_context.parent

        package_name = if parsed_doc.has_route_option?(:from)
          parsed_doc.route_option_value(:from)
        else
          package_name_from_uri(@uri)
        end 

        ree_object = @finder.find_object_for_package(node.unescaped, package_name)
        return [] unless ree_object

        [
          Interface::Location.new(
            uri: ree_object.uri.to_s,
            range: Interface::Range.new(
              start: Interface::Position.new(line: 0, character: 0),
              end: Interface::Position.new(line: 0, character: 0),
            ),
          )
        ]
      end

      def get_linked_filepath_definition_items(node)
        result = []
        local_path = find_local_file_path(node.unescaped)

        return [] unless local_path

        result << Interface::Location.new(
          uri: File.join(Dir.pwd, local_path),
          range: Interface::Range.new(
            start: Interface::Position.new(line: 0, character: 0),
            end: Interface::Position.new(line: 0, character: 0),
          ),
        )
      end

      def get_error_locales_definition_items(node)
        locales_folder = package_locales_folder_path(@uri.path)

        return [] unless File.directory?(locales_folder)

        result = []
        key_path = node.unescaped

        Dir.glob(File.join(locales_folder, '**/*.yml')).each do |locale_file|
          location = find_locale_key_location(locale_file, key_path)

          result << Interface::Location.new(
            uri: locale_file,
            range: Interface::Range.new(
              start: Interface::Position.new(line: location.line, character: location.column),
              end: Interface::Position.new(line: location.line, character: location.column),
            ),
          )
        end

        result
      end

      def get_error_code_definition_items(node)
        locales_folder = package_locales_folder_path(@uri.path)
        return [] unless File.directory?(locales_folder)

        result = []

        key_path_entries = if @node_context.parent.arguments.arguments.size > 1
          [@node_context.parent.arguments.arguments[1].unescaped]
        else
          parsed_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_ast(@root_node, @uri)
          file_name = File.basename(@uri.path, '.rb')

          mod = underscore(parsed_doc.module_name)
          [
            "#{mod}.errors.#{node.unescaped}",
            "#{mod}.errors.#{file_name}.#{node.unescaped}"
          ]
        end

        Dir.glob(File.join(locales_folder, '**/*.yml')).each do |locale_file|
          values = key_path_entries.map{ [_1, find_locale_value(locale_file, _1)] }
          key_path = values.select{ |val| !val[1].nil? }.last
          next unless key_path
          
          location = find_locale_key_location(locale_file, key_path[0])

          result << Interface::Location.new(
            uri: locale_file,
            range: Interface::Range.new(
              start: Interface::Position.new(line: location.line, character: location.column),
              end: Interface::Position.new(line: location.line, character: location.column),
            ),
          )
        end

        result
      end

      def get_package_definition_items(node)
        package_name = node.unescaped

        parent_node = @node_context.parent
        link_node = RubyLsp::Ree::ParsedLinkNodeBuilder.build_from_node(parent_node, package_name_from_uri(@uri))

        method_candidates = @index[link_node.name]
        return [] if !method_candidates || method_candidates.size == 0
        
        method = method_candidates.detect{ package_name_from_uri(_1.uri) == package_name }
        return [] unless method

        package_path = package_path_from_uri(method.uri.to_s)
        package_main_file_path = File.join(package_path, 'package', "#{package_name}.rb")

        [
          Interface::Location.new(
            uri: package_main_file_path,
            range: Interface::Range.new(
              start: Interface::Position.new(line: 0, character: 0),
              end: Interface::Position.new(line: 0, character: 0),
            ),
          )
        ]
      end
    end
  end
end