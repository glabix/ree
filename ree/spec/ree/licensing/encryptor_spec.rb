# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ree::Licensing::Encryptor do
  describe 'AES encryption round-trip' do
    it 'encrypts and decrypts data correctly' do
      aes_data = described_class.generate_aes_key
      key = aes_data[:key]
      iv = aes_data[:iv]

      plaintext = "Hello, this is some test data for AES encryption!"
      encrypted = described_class.aes_encrypt(plaintext, key, iv)

      expect(encrypted).not_to eq(plaintext)
      expect(encrypted.encoding).to eq(Encoding::ASCII_8BIT)

      decrypted = described_class.aes_decrypt(encrypted, key, iv)
      expect(decrypted).to eq(plaintext)
    end

    it 'generates different keys each time' do
      aes1 = described_class.generate_aes_key
      aes2 = described_class.generate_aes_key

      expect(aes1[:key]).not_to eq(aes2[:key])
    end

    it 'handles binary data' do
      aes_data = described_class.generate_aes_key
      binary_data = (0..255).map(&:chr).join
      encrypted = described_class.aes_encrypt(binary_data, aes_data[:key], aes_data[:iv])
      decrypted = described_class.aes_decrypt(encrypted, aes_data[:key], aes_data[:iv])

      expect(decrypted).to eq(binary_data)
    end
  end

  describe 'RSA encryption round-trip' do
    it 'encrypts with private key and decrypts with public key' do
      rsa = OpenSSL::PKey::RSA.new(2048)
      payload = '{"key": "value"}'

      encrypted = described_class.rsa_private_encrypt(payload, rsa.to_pem)
      decrypted = described_class.rsa_public_decrypt(encrypted, rsa.public_key.to_pem)

      expect(decrypted).to eq(payload)
    end
  end
end
