RSpec.describe 'Ree::Contracts no_contract ENV' do
  around {
    contracts_enabled = !Ree::Contracts.no_contracts?
    Ree.disable_contracts
    _1.run
    Ree.enable_contracts if contracts_enabled
  }

  it {
    expect(Ree::Contracts.no_contracts?).to be_truthy
  }

  it {
    expect(
      Class.new do
        contract String => nil
        def call(name); end

        contract Symbol => nil
        def method(name); end
      end.new.call(:no_string)
    ).to be_nil
  }
end
