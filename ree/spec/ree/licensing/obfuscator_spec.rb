# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'json'
require 'date'

RSpec.describe Ree::Licensing::Obfuscator do
  let(:tmp_dir) { Dir.mktmpdir }
  let(:source_path) { File.join(tmp_dir, 'source_project') }
  let(:target_path) { File.join(tmp_dir, 'dist') }
  let(:clients_dir) { File.join(tmp_dir, 'clients') }
  let(:stdout) { StringIO.new }

  before do
    FileUtils.mkdir_p(clients_dir)

    # Create a minimal Ree-like project structure
    FileUtils.mkdir_p(File.join(source_path, 'my_package/package/my_package'))
    FileUtils.mkdir_p(File.join(source_path, 'my_package/spec'))

    # Package entry file
    File.write(
      File.join(source_path, 'my_package/package/my_package.rb'),
      <<~RUBY
        module MyPackageEntry
          def self.hello
            "hello from entry"
          end
        end
      RUBY
    )

    # An object file inside the package
    File.write(
      File.join(source_path, 'my_package/package/my_package/greeter.rb'),
      <<~RUBY
        module MyPackageGreeter
          def self.greet(name)
            "Hello, \#{name}!"
          end
        end
      RUBY
    )

    # A spec file (should be removed)
    File.write(
      File.join(source_path, 'my_package/spec/greeter_spec.rb'),
      "# spec file"
    )

    # A non-rb file (should not be encrypted)
    File.write(
      File.join(source_path, 'my_package/package/my_package/config.json'),
      '{"key": "value"}'
    )

    # Register a client
    store = Ree::Licensing::ClientStore.new(clients_dir)
    @client = store.register_client(name: 'TestClient', contact: 'test@test.com')
  end

  after do
    FileUtils.rm_rf(tmp_dir)
    Object.send(:remove_const, :MyPackageEntry) if defined?(MyPackageEntry)
    Object.send(:remove_const, :MyPackageGreeter) if defined?(MyPackageGreeter)
  end

  describe '.run' do
    it 'obfuscates all .rb files in package directories' do
      result = described_class.run(
        source_path: source_path,
        target_path: target_path,
        client_id: @client['client_id'],
        expires_at: (Date.today + 365).to_s,
        clients_dir: clients_dir,
        stdout: stdout
      )

      expect(result[:encrypted_count]).to eq(2)
      expect(File.exist?(result[:license_path])).to be true

      # Verify encrypted files are not readable as Ruby source
      entry_content = File.binread(File.join(target_path, 'my_package/package/my_package.rb'))
      expect(entry_content).not_to include('module')

      greeter_content = File.binread(File.join(target_path, 'my_package/package/my_package/greeter.rb'))
      expect(greeter_content).not_to include('def self.greet')
    end

    it 'removes spec directories' do
      described_class.run(
        source_path: source_path,
        target_path: target_path,
        client_id: @client['client_id'],
        expires_at: (Date.today + 365).to_s,
        clients_dir: clients_dir,
        stdout: stdout
      )

      expect(Dir.exist?(File.join(target_path, 'my_package/spec'))).to be false
    end

    it 'preserves non-rb files' do
      described_class.run(
        source_path: source_path,
        target_path: target_path,
        client_id: @client['client_id'],
        expires_at: (Date.today + 365).to_s,
        clients_dir: clients_dir,
        stdout: stdout
      )

      json_content = File.read(File.join(target_path, 'my_package/package/my_package/config.json'))
      expect(JSON.parse(json_content)).to eq({ 'key' => 'value' })
    end

    it 'creates a valid license.json' do
      described_class.run(
        source_path: source_path,
        target_path: target_path,
        client_id: @client['client_id'],
        expires_at: (Date.today + 365).to_s,
        clients_dir: clients_dir,
        stdout: stdout
      )

      license = JSON.parse(File.read(File.join(target_path, 'license.json')))
      expect(license['version']).to eq(1)
      expect(license['client_id']).to eq(@client['client_id'])
      expect(license['public_key_pem']).to include('PUBLIC KEY')
      expect(license['encrypted_payload']).to be_a(String)
    end

    it 'saves license record to clients.json' do
      described_class.run(
        source_path: source_path,
        target_path: target_path,
        client_id: @client['client_id'],
        expires_at: (Date.today + 365).to_s,
        clients_dir: clients_dir,
        stdout: stdout
      )

      store = Ree::Licensing::ClientStore.new(clients_dir)
      last_lic = store.last_license(@client['client_id'])
      expect(last_lic['license_id']).to match(/\Alic_/)
      expect(last_lic['expires_at']).to eq((Date.today + 365).to_s)
      expect(last_lic['aes_key_hex']).to be_a(String)
      expect(last_lic['iv_hex']).to be_a(String)
    end

    it 'raises error if file contains require_relative' do
      File.write(
        File.join(source_path, 'my_package/package/my_package/greeter.rb'),
        "require_relative 'something'\nmodule Greeter; end"
      )

      expect {
        described_class.run(
          source_path: source_path,
          target_path: target_path,
          client_id: @client['client_id'],
          expires_at: (Date.today + 365).to_s,
          clients_dir: clients_dir,
          stdout: stdout
        )
      }.to raise_error(Ree::Error, /require_relative/)
    end

    it 'excludes specified files' do
      result = described_class.run(
        source_path: source_path,
        target_path: target_path,
        client_id: @client['client_id'],
        expires_at: (Date.today + 365).to_s,
        clients_dir: clients_dir,
        exclude_files: ['greeter.rb'],
        stdout: stdout
      )

      expect(result[:encrypted_count]).to eq(1)

      # greeter.rb should still be readable as source
      greeter = File.read(File.join(target_path, 'my_package/package/my_package/greeter.rb'))
      expect(greeter).to include('def self.greet')
    end

    it 'handles nested package directories (e.g. bc/accounts/package/)' do
      # Add a nested package like a real Ree project
      FileUtils.mkdir_p(File.join(source_path, 'bc/accounts/package/accounts'))
      File.write(
        File.join(source_path, 'bc/accounts/package/accounts.rb'),
        <<~RUBY
          module NestedPackageEntry
            def self.value
              99
            end
          end
        RUBY
      )
      File.write(
        File.join(source_path, 'bc/accounts/package/accounts/service.rb'),
        <<~RUBY
          module NestedService
            def self.call
              "nested"
            end
          end
        RUBY
      )

      result = described_class.run(
        source_path: source_path,
        target_path: target_path,
        client_id: @client['client_id'],
        expires_at: (Date.today + 365).to_s,
        clients_dir: clients_dir,
        stdout: stdout
      )

      # 2 from my_package + 2 from bc/accounts = 4
      expect(result[:encrypted_count]).to eq(4)

      # Verify nested files are encrypted
      nested_entry = File.binread(File.join(target_path, 'bc/accounts/package/accounts.rb'))
      expect(nested_entry).not_to include('module')
    ensure
      Object.send(:remove_const, :NestedPackageEntry) if defined?(NestedPackageEntry)
      Object.send(:remove_const, :NestedService) if defined?(NestedService)
    end

    it 'raises error for unknown client' do
      expect {
        described_class.run(
          source_path: source_path,
          target_path: target_path,
          client_id: 'client_nonexistent',
          expires_at: (Date.today + 365).to_s,
          clients_dir: clients_dir,
          stdout: stdout
        )
      }.to raise_error(Ree::Error, /not found/)
    end

    context 'full round-trip: obfuscate and decrypt' do
      it 'decrypts obfuscated files back to working bytecode' do
        described_class.run(
          source_path: source_path,
          target_path: target_path,
          client_id: @client['client_id'],
          expires_at: (Date.today + 365).to_s,
          clients_dir: clients_dir,
          stdout: stdout
        )

        license_path = File.join(target_path, 'license.json')
        decryptor = Ree::Licensing::Decryptor.load_license(license_path)

        # Decrypt and load the entry file
        encrypted_entry = File.binread(File.join(target_path, 'my_package/package/my_package.rb'))
        bytecode = decryptor.decrypt_file(encrypted_entry)
        iseq = RubyVM::InstructionSequence.load_from_binary(bytecode)
        iseq.eval

        expect(MyPackageEntry.hello).to eq("hello from entry")

        # Decrypt and load the greeter file
        encrypted_greeter = File.binread(File.join(target_path, 'my_package/package/my_package/greeter.rb'))
        bytecode2 = decryptor.decrypt_file(encrypted_greeter)
        iseq2 = RubyVM::InstructionSequence.load_from_binary(bytecode2)
        iseq2.eval

        expect(MyPackageGreeter.greet("World")).to eq("Hello, World!")
      end
    end
  end
end
