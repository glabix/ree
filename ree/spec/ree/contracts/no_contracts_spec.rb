RSpec.describe 'Ree::Contracts no_contract ENV' do
  before {
    ENV['NO_CONTRACTS'] = 't'
  }

  after {
    ENV['NO_CONTRACTS'] = nil
  }

  it {
    expect(Ree::Contracts.no_contracts?).to be_truthy
  }

  it {
    expect(
      Class.new do
        contract String => nil
        def call(name); end
      end.new.call(:no_string)
    ).to be_nil
  }
end
