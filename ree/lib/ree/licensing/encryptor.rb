# frozen_string_literal: true

require 'openssl'
require 'securerandom'
require 'json'
require 'base64'

module Ree
  module Licensing
    class Encryptor
      def self.generate_aes_key
        cipher = OpenSSL::Cipher::AES256.new(:CBC)
        cipher.encrypt
        {
          key: cipher.random_key,
          iv: cipher.random_iv
        }
      end

      def self.aes_encrypt(data, key, iv)
        cipher = OpenSSL::Cipher::AES256.new(:CBC)
        cipher.encrypt
        cipher.key = key
        cipher.iv = iv
        cipher.update(data) + cipher.final
      end

      def self.aes_decrypt(encrypted_data, key, iv)
        cipher = OpenSSL::Cipher::AES256.new(:CBC)
        cipher.decrypt
        cipher.key = key
        cipher.iv = iv
        cipher.update(encrypted_data) + cipher.final
      end

      def self.rsa_private_encrypt(payload_json, private_key_pem)
        rsa = OpenSSL::PKey::RSA.new(private_key_pem)
        rsa.private_encrypt(payload_json)
      end

      def self.rsa_public_decrypt(encrypted_payload, public_key_pem)
        rsa = OpenSSL::PKey::RSA.new(public_key_pem)
        rsa.public_decrypt(encrypted_payload)
      end
    end
  end
end
