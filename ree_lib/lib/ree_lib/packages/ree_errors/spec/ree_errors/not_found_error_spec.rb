package_require('ree_errors/not_found_error')

RSpec.describe ReeErrors::NotFoundError do
  link :not_found_error, from: :ree_errors

  it {
    klass = not_found_error(:code)
    error = klass.new('message')

    expect(klass).to be_a(Class)
    expect(error).to be_a(ReeErrors::Error)
    expect(error.message).to eq('message')
    expect(error.code).to eq(:code)
    expect(error.type).to eq(:not_found)
    expect(error.locale).to eq(nil)
  }
end