# frozen_string_literal: true

require 'json'
require 'securerandom'
require 'openssl'

module Ree
  module Licensing
    class ClientStore
      CLIENTS_FILE = 'clients.json'

      def initialize(dir)
        @dir = dir
        @file_path = File.join(dir, CLIENTS_FILE)
      end

      def register_client(name:, contact:, metadata: {})
        data = load_data
        client_id = "client_#{SecureRandom.hex(8)}"
        rsa_key = OpenSSL::PKey::RSA.new(4096)

        client = {
          'client_id' => client_id,
          'name' => name,
          'contact' => contact,
          'metadata' => metadata,
          'created_at' => Date.today.to_s,
          'private_key_pem' => rsa_key.to_pem,
          'public_key_pem' => rsa_key.public_key.to_pem,
          'licenses' => []
        }

        data['clients'] << client
        save_data(data)

        client
      end

      def find_client(client_id)
        data = load_data
        data['clients'].detect { |c| c['client_id'] == client_id }
      end

      def add_license(client_id, license)
        data = load_data
        client = data['clients'].detect { |c| c['client_id'] == client_id }
        raise Ree::Error.new("Client #{client_id} not found") unless client

        client['licenses'] << license
        save_data(data)
      end

      def last_license(client_id)
        client = find_client(client_id)
        raise Ree::Error.new("Client #{client_id} not found") unless client

        client['licenses'].last
      end

      def load_data
        if File.exist?(@file_path)
          JSON.parse(File.read(@file_path))
        else
          { 'clients' => [] }
        end
      end

      private

      def save_data(data)
        File.write(@file_path, JSON.pretty_generate(data))
      end
    end
  end
end
