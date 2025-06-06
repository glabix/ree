require "ruby_lsp/addon"
require_relative "listeners/definition_listener"
require_relative "listeners/completion_listener"
require_relative "listeners/hover_listener"
require_relative "ree_indexing_enhancement"
require_relative "utils/ree_lsp_utils"
require_relative "ree_formatter"
require_relative "ree_template_applicator"
require_relative "ree_rename_handler"
require_relative "ree_constants"
require_relative "parsing/parsed_document_builder"

module RubyLsp
  module Ree
    class Addon < ::RubyLsp::Addon
      def activate(global_state, message_queue)
        @global_state = global_state
        @settings = global_state.settings_for_addon(name) || {}

        @message_queue = message_queue
        @template_applicator = RubyLsp::Ree::ReeTemplateApplicator.new
        
        global_state.register_formatter("ree_formatter", RubyLsp::Ree::ReeFormatter.new(
          @message_queue, 
          @settings[:formatter], 
          @global_state.index
        ))

        register_additional_file_watchers(global_state, message_queue)
      end

      def deactivate
      end

      def name
        "Ree Addon"
      end

      def create_definition_listener(response_builder, uri, node_context, dispatcher)
        index = @global_state.index
        RubyLsp::Ree::DefinitionListener.new(response_builder, node_context, index, dispatcher, uri)
      end

      def create_completion_listener(response_builder, node_context, dispatcher, uri)
        index = @global_state.index
        RubyLsp::Ree::CompletionListener.new(response_builder, node_context, index, dispatcher, uri)
      end

      def create_hover_listener(response_builder, node_context, dispatcher)
        index = @global_state.index
        RubyLsp::Ree::HoverListener.new(response_builder, node_context, index, dispatcher)
      end

      def register_additional_file_watchers(global_state, message_queue)
        # Clients are not required to implement this capability
        return unless global_state.supports_watching_files
        
        message_queue << Request.new(
          id: "ruby-lsp-ree-file-create-watcher",
          method: "client/registerCapability",
          params: Interface::RegistrationParams.new(
            registrations: [
              Interface::Registration.new(
                id: "workspace/didCreateWatchedFilesRee",
                method: "workspace/didChangeWatchedFiles",
                register_options: Interface::DidChangeWatchedFilesRegistrationOptions.new(
                  watchers: [
                    Interface::FileSystemWatcher.new(
                      glob_pattern: "**/*.rb",
                      kind: Constant::WatchKind::CREATE | Constant::WatchKind::CHANGE,
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
      end

      def workspace_did_change_watched_files(changes)
        if changes.size == 1 && changes[0][:type] == Constant::FileChangeType::CREATED
          $stderr.puts("file created #{changes[0][:uri]}")

          return unless @template_applicator.template_dir_exists?

          @template_applicator.apply(changes[0])
        elsif changes.size == 2 && changes.any?{ _1[:type] == Constant::FileChangeType::CREATED } && changes.any?{ _1[:type] == Constant::FileChangeType::DELETED }
          $stderr.puts("file renamed #{changes[0][:uri]} #{changes[1][:uri]}")
  
          RubyLsp::Ree::ReeRenameHandler.call(changes)
        end
      end
    end
  end
end