package_require('ree_errors/payment_required_error')

RSpec.describe ReeErrors::PaymentRequiredError do
  it {
    klass = described_class.build(:code)
    error = klass.new('message')

    expect(klass).to be_a(Class)
    expect(error).to be_a(ReeErrors::Error)
    expect(error.message).to eq('message')
    expect(error.code).to eq(:code)
    expect(error.type).to eq(:payment_required)
    expect(error.locale).to eq(nil)
  }
end