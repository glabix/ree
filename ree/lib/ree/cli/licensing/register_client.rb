# frozen_string_literal: true

module Ree
  module CLI
    module Licensing
      class RegisterClient
        class << self
          def run(name:, contact:, metadata_str: nil, clients_dir: Dir.pwd, stdout: $stdout)
            metadata = parse_metadata(metadata_str)

            store = Ree::Licensing::ClientStore.new(clients_dir)
            client = store.register_client(
              name: name,
              contact: contact,
              metadata: metadata
            )

            stdout.puts "Client registered successfully:"
            stdout.puts "  Client ID: #{client['client_id']}"
            stdout.puts "  Name: #{client['name']}"
            stdout.puts "  Contact: #{client['contact']}"
            stdout.puts "  Saved to: #{File.join(clients_dir, 'clients.json')}"

            client
          rescue Ree::Error => e
            stdout.puts "Error: #{e.message}"
          end

          private

          def parse_metadata(metadata_str)
            return {} if metadata_str.nil? || metadata_str.empty?

            metadata_str.split(',').each_with_object({}) do |pair, hash|
              key, value = pair.split('=', 2)
              hash[key.strip] = value&.strip
            end
          end
        end
      end
    end
  end
end
