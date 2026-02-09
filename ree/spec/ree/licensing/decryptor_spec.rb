# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'json'
require 'date'

RSpec.describe Ree::Licensing::Decryptor do
  let(:rsa_key) { OpenSSL::PKey::RSA.new(2048) }
  let(:aes_data) { Ree::Licensing::Encryptor.generate_aes_key }
  let(:aes_key_hex) { aes_data[:key].unpack1('H*') }
  let(:iv_hex) { aes_data[:iv].unpack1('H*') }

  def create_license_file(tmp_dir, expires_at:)
    payload = {
      'aes_key_hex' => aes_key_hex,
      'iv_hex' => iv_hex,
      'expires_at' => expires_at,
      'client_id' => 'client_test123'
    }

    encrypted_payload = Ree::Licensing::Encryptor.rsa_private_encrypt(
      JSON.generate(payload), rsa_key.to_pem
    )

    license_data = {
      'version' => 1,
      'client_id' => 'client_test123',
      'public_key_pem' => rsa_key.public_key.to_pem,
      'encrypted_payload' => Base64.strict_encode64(encrypted_payload)
    }

    license_path = File.join(tmp_dir, 'license.json')
    File.write(license_path, JSON.generate(license_data))
    license_path
  end

  describe '.load_license' do
    it 'loads a valid license' do
      tmp_dir = Dir.mktmpdir
      license_path = create_license_file(tmp_dir, expires_at: (Date.today + 30).to_s)

      decryptor = described_class.load_license(license_path)

      expect(decryptor.client_id).to eq('client_test123')
      expect(decryptor.expires_at).to eq(Date.today + 30)
      expect(decryptor.aes_key).to eq(aes_data[:key])
      expect(decryptor.iv).to eq(aes_data[:iv])
    ensure
      FileUtils.rm_rf(tmp_dir)
    end

    it 'raises error for expired license' do
      tmp_dir = Dir.mktmpdir
      license_path = create_license_file(tmp_dir, expires_at: (Date.today - 1).to_s)

      expect {
        described_class.load_license(license_path)
      }.to raise_error(Ree::Error, /expired/)
    ensure
      FileUtils.rm_rf(tmp_dir)
    end

    it 'raises error for missing license file' do
      expect {
        described_class.load_license('/nonexistent/path/license.json')
      }.to raise_error(Ree::Error, /not found/)
    end
  end

  describe '#decrypt_file' do
    it 'decrypts AES encrypted data' do
      decryptor = described_class.new(
        aes_key: aes_data[:key],
        iv: aes_data[:iv],
        expires_at: Date.today + 30,
        client_id: 'test'
      )

      plaintext = "Some binary content here"
      encrypted = Ree::Licensing::Encryptor.aes_encrypt(plaintext, aes_data[:key], aes_data[:iv])

      result = decryptor.decrypt_file(encrypted)
      expect(result).to eq(plaintext)
    end
  end
end
