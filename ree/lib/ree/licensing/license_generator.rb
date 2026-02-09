# frozen_string_literal: true

require 'json'
require 'base64'
require 'securerandom'

module Ree
  module Licensing
    class LicenseGenerator
      def self.generate(client_id:, private_key_pem:, public_key_pem:, aes_key_hex:, iv_hex:, expires_at:)
        payload = {
          'aes_key_hex' => aes_key_hex,
          'iv_hex' => iv_hex,
          'expires_at' => expires_at,
          'client_id' => client_id
        }

        payload_json = JSON.generate(payload)
        encrypted_payload = Encryptor.rsa_private_encrypt(payload_json, private_key_pem)

        license_file = {
          'version' => 1,
          'client_id' => client_id,
          'public_key_pem' => public_key_pem,
          'encrypted_payload' => Base64.strict_encode64(encrypted_payload)
        }

        license_record = {
          'license_id' => "lic_#{SecureRandom.hex(6)}",
          'expires_at' => expires_at,
          'aes_key_hex' => aes_key_hex,
          'iv_hex' => iv_hex,
          'created_at' => Date.today.to_s
        }

        { license_file: license_file, license_record: license_record }
      end
    end
  end
end
