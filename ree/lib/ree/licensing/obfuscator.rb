# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'date'

module Ree
  module Licensing
    class Obfuscator
      def self.run(source_path:, target_path:, client_id:, expires_at:, clients_dir:, exclude_files: [], stdout: $stdout)
        new(
          source_path: source_path,
          target_path: target_path,
          client_id: client_id,
          expires_at: expires_at,
          clients_dir: clients_dir,
          exclude_files: exclude_files,
          stdout: stdout
        ).run
      end

      def initialize(source_path:, target_path:, client_id:, expires_at:, clients_dir:, exclude_files: [], stdout: $stdout)
        @source_path = File.expand_path(source_path)
        @target_path = File.expand_path(target_path)
        @client_id = client_id
        @expires_at = expires_at
        @clients_dir = clients_dir
        @exclude_files = exclude_files
        @stdout = stdout
      end

      def run
        start_time = Time.now

        store = ClientStore.new(@clients_dir)
        client = store.find_client(@client_id)
        raise Ree::Error.new("Client #{@client_id} not found in clients.json") unless client

        copy_project
        remove_spec_dirs

        aes_data = Encryptor.generate_aes_key
        aes_key = aes_data[:key]
        iv = aes_data[:iv]
        aes_key_hex = aes_key.unpack1('H*')
        iv_hex = iv.unpack1('H*')

        encrypted_count = encrypt_ruby_files(aes_key, iv)

        result = LicenseGenerator.generate(
          client_id: @client_id,
          private_key_pem: client['private_key_pem'],
          public_key_pem: client['public_key_pem'],
          aes_key_hex: aes_key_hex,
          iv_hex: iv_hex,
          expires_at: @expires_at
        )

        license_path = File.join(@target_path, 'license.json')
        File.write(license_path, JSON.pretty_generate(result[:license_file]))

        store.add_license(@client_id, result[:license_record])

        elapsed = (Time.now - start_time).round(2)
        @stdout.puts "Obfuscation complete:"
        @stdout.puts "  Files encrypted: #{encrypted_count}"
        @stdout.puts "  License file: #{license_path}"
        @stdout.puts "  Time: #{elapsed}s"

        { encrypted_count: encrypted_count, license_path: license_path }
      end

      private

      def copy_project
        FileUtils.rm_rf(@target_path) if Dir.exist?(@target_path)
        FileUtils.cp_r(@source_path, @target_path)
      end

      def remove_spec_dirs
        Dir.glob(File.join(@target_path, '**/spec')).each do |spec_dir|
          FileUtils.rm_rf(spec_dir) if File.directory?(spec_dir)
        end
      end

      def encrypt_ruby_files(aes_key, iv)
        count = 0
        pattern = File.join(@target_path, '*/package/**/*.rb')

        Dir.glob(pattern).each do |file_path|
          basename = File.basename(file_path)
          next if @exclude_files.include?(basename)

          source = File.read(file_path)
          if source.include?('require_relative')
            raise Ree::Error.new("File contains require_relative: #{file_path}")
          end

          bytecode = BytecodeCompiler.compile_file(file_path)
          encrypted = Encryptor.aes_encrypt(bytecode, aes_key, iv)
          File.binwrite(file_path, encrypted)
          count += 1
        end

        count
      end
    end
  end
end
