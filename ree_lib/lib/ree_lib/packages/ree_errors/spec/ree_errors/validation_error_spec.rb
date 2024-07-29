package_require('ree_errors/validation_error')

RSpec.describe ReeErrors::ValidationError do
  link :validation_error, from: :ree_errors

  it {
    klass = validation_error(:code)
    error = klass.new('message')

    expect(klass).to be_a(Class)
    expect(error).to be_a(ReeErrors::Error)
    expect(error.message).to eq('message')
    expect(error.code).to eq(:code)
    expect(error.type).to eq(:validation)
    expect(error.locale).to eq(nil)
  }
end