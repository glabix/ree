package_require('ree_errors/invalid_param_error')

RSpec.describe ReeErrors::InvalidParamError do
  link :invalid_param_error, from: :ree_errors

  it {
    klass = invalid_param_error(:code)
    error = klass.new('message')

    expect(klass).to be_a(Class)
    expect(error).to be_a(ReeErrors::Error)
    expect(error.message).to eq('message')
    expect(error.code).to eq(:code)
    expect(error.type).to eq(:invalid_param)
    expect(error.locale).to eq(nil)
  }

  it {
    klass = invalid_param_error(:locale_error1)
    error = klass.new

    expect(klass).to be_a(Class)
    expect(error).to be_a(ReeErrors::Error)
    expect(error.message).to eq('locale error 1')
    expect(error.code).to eq(:locale_error1)
    expect(error.type).to eq(:invalid_param)
    expect(error.locale).to eq(nil)
  }
end
