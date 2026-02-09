# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe Ree::Licensing::ClientStore do
  let(:tmp_dir) { Dir.mktmpdir }
  let(:store) { described_class.new(tmp_dir) }

  after { FileUtils.rm_rf(tmp_dir) }

  describe '#register_client' do
    it 'creates a new client with RSA keypair' do
      client = store.register_client(
        name: 'TestCorp',
        contact: 'test@example.com',
        metadata: { 'type' => 'enterprise' }
      )

      expect(client['client_id']).to match(/\Aclient_[a-f0-9]{16}\z/)
      expect(client['name']).to eq('TestCorp')
      expect(client['contact']).to eq('test@example.com')
      expect(client['metadata']).to eq({ 'type' => 'enterprise' })
      expect(client['private_key_pem']).to include('RSA PRIVATE KEY')
      expect(client['public_key_pem']).to include('PUBLIC KEY')
      expect(client['licenses']).to eq([])
    end

    it 'persists client data to clients.json' do
      store.register_client(name: 'Corp1', contact: 'a@b.com')
      store.register_client(name: 'Corp2', contact: 'c@d.com')

      data = store.load_data
      expect(data['clients'].size).to eq(2)
      expect(data['clients'][0]['name']).to eq('Corp1')
      expect(data['clients'][1]['name']).to eq('Corp2')
    end
  end

  describe '#find_client' do
    it 'finds an existing client by client_id' do
      client = store.register_client(name: 'FindMe', contact: 'find@me.com')
      found = store.find_client(client['client_id'])

      expect(found['name']).to eq('FindMe')
    end

    it 'returns nil for unknown client_id' do
      expect(store.find_client('nonexistent')).to be_nil
    end
  end

  describe '#add_license' do
    it 'adds a license record to the client' do
      client = store.register_client(name: 'LicCorp', contact: 'lic@corp.com')
      license = { 'license_id' => 'lic_123', 'expires_at' => '2027-01-01' }

      store.add_license(client['client_id'], license)

      updated = store.find_client(client['client_id'])
      expect(updated['licenses'].size).to eq(1)
      expect(updated['licenses'][0]['license_id']).to eq('lic_123')
    end

    it 'raises error for unknown client' do
      expect {
        store.add_license('nonexistent', {})
      }.to raise_error(Ree::Error, /not found/)
    end
  end

  describe '#last_license' do
    it 'returns the most recent license' do
      client = store.register_client(name: 'Corp', contact: 'c@c.com')
      store.add_license(client['client_id'], { 'license_id' => 'lic_1' })
      store.add_license(client['client_id'], { 'license_id' => 'lic_2' })

      last = store.last_license(client['client_id'])
      expect(last['license_id']).to eq('lic_2')
    end

    it 'raises error for unknown client' do
      expect {
        store.last_license('nonexistent')
      }.to raise_error(Ree::Error, /not found/)
    end
  end
end
