# frozen_string_literal: true

require 'json'
require 'base64'
require 'openssl'
require 'date'

module Ree
  module Licensing
    class Decryptor
      attr_reader :aes_key, :iv, :expires_at, :client_id

      def initialize(aes_key:, iv:, expires_at:, client_id:)
        @aes_key = aes_key
        @iv = iv
        @expires_at = expires_at
        @client_id = client_id
      end

      def self.load_license(license_path)
        unless File.exist?(license_path)
          raise Ree::Error.new("License file not found: #{license_path}")
        end

        license_data = JSON.parse(File.read(license_path))
        public_key_pem = license_data['public_key_pem']
        encrypted_payload = Base64.strict_decode64(license_data['encrypted_payload'])

        payload_json = Encryptor.rsa_public_decrypt(encrypted_payload, public_key_pem)
        payload = JSON.parse(payload_json)

        expires_at = Date.parse(payload['expires_at'])

        if expires_at < Date.today
          raise Ree::Error.new("License expired on #{payload['expires_at']}")
        end

        aes_key = [payload['aes_key_hex']].pack('H*')
        iv = [payload['iv_hex']].pack('H*')

        new(
          aes_key: aes_key,
          iv: iv,
          expires_at: expires_at,
          client_id: payload['client_id']
        )
      end

      def decrypt_file(encrypted_data)
        Encryptor.aes_decrypt(encrypted_data, @aes_key, @iv)
      end
    end
  end
end
