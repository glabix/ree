# frozen_string_literal: true

require 'json'

module Ree
  module CLI
    module Licensing
      class RenewLicense
        class << self
          def run(client_id:, expires_at:, output_path: nil, clients_dir: Dir.pwd, stdout: $stdout)
            store = Ree::Licensing::ClientStore.new(clients_dir)
            client = store.find_client(client_id)
            raise Ree::Error.new("Client #{client_id} not found") unless client

            last_license = store.last_license(client_id)
            raise Ree::Error.new("No existing license found for #{client_id}") unless last_license

            result = Ree::Licensing::LicenseGenerator.generate(
              client_id: client_id,
              private_key_pem: client['private_key_pem'],
              public_key_pem: client['public_key_pem'],
              aes_key_hex: last_license['aes_key_hex'],
              iv_hex: last_license['iv_hex'],
              expires_at: expires_at
            )

            store.add_license(client_id, result[:license_record])

            output = output_path || File.join(clients_dir, "license_#{client_id}.json")
            File.write(output, JSON.pretty_generate(result[:license_file]))

            stdout.puts "License renewed successfully:"
            stdout.puts "  Client ID: #{client_id}"
            stdout.puts "  Expires at: #{expires_at}"
            stdout.puts "  License file: #{output}"

            result
          rescue Ree::Error => e
            stdout.puts "Error: #{e.message}"
          end
        end
      end
    end
  end
end
