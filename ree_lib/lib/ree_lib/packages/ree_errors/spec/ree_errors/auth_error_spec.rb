package_require('ree_errors/auth_error')

RSpec.describe ReeErrors::AuthError do
  link :add_load_path, from: :ree_i18n
  link :auth_error, from: :ree_errors

  before :all do
    add_load_path(Dir[File.join(__dir__, 'locales/*.yml')])
  end

  it {
    klass = auth_error(:code, 'ree_errors_test.error', msg: "test")
    error = klass.new

    expect(klass).to be_a(Class)
    expect(error).to be_a(ReeErrors::Error)
    expect(error.message).to eq('test')
    expect(error.code).to eq(:code)
    expect(error.type).to eq(:auth)
    expect(error.locale).to eq('ree_errors_test.error')
    expect(error.caller).to eq(self)
  }

  it {
    klass = auth_error(:code)

    expect {
      klass.new
    }.to raise_error(ArgumentError)
  }

  it {
    klass = auth_error(:code)
    error = klass.new('CUSTOM MESSAGE')

    expect(klass).to be_a(Class)
    expect(error).to be_a(ReeErrors::Error)
    expect(error.message).to eq('CUSTOM MESSAGE')
    expect(error.code).to eq(:code)
    expect(error.type).to eq(:auth)
    expect(error.locale).to eq(nil)
  }

  it {
    klass = auth_error(:code, 'locale_error')
    error = klass.new

    expect(klass).to be_a(Class)
    expect(error).to be_a(ReeErrors::Error)
    expect(error.message).to eq('locale error')
    expect(error.code).to eq(:code)
    expect(error.type).to eq(:auth)
    expect(error.locale).to eq("locale_error")
  }

  it {
    klass = auth_error(:code, 'locale_error1')
    error = klass.new

    expect(klass).to be_a(Class)
    expect(error).to be_a(ReeErrors::Error)
    expect(error.message).to eq('locale error 1')
    expect(error.code).to eq(:code)
    expect(error.type).to eq(:auth)
    expect(error.locale).to eq("locale_error1")
  }
end