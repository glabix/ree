package_require('ree_errors/auth_error')

RSpec.describe ReeErrors::AuthError do
  link :add_load_path, from: :ree_i18n

  before :all do
    add_load_path(Dir[File.join(__dir__, 'locales/*.yml')])
  end

  it {
    klass = described_class.build(:code, 'ree_errors_test.error')
    error = klass.new('CUSTOM MESSAGE')

    expect(klass).to be_a(Class)
    expect(error).to be_a(ReeErrors::Error)
    expect(error.message).to eq('test error message')
    expect(error.code).to eq(:code)
    expect(error.type).to eq(:auth)
    expect(error.locale).to eq('ree_errors_test.error')
  }

  it {
    klass = described_class.build(:code)

    expect {
      klass.new
    }.to raise_error(ArgumentError)
  }

  it {
    klass = described_class.build(:code)
    error = klass.new('CUSTOM MESSAGE')

    expect(klass).to be_a(Class)
    expect(error).to be_a(ReeErrors::Error)
    expect(error.message).to eq('CUSTOM MESSAGE')
    expect(error.code).to eq(:code)
    expect(error.type).to eq(:auth)
    expect(error.locale).to eq(nil)
  }

  it {
    klass = described_class.build(:code, 'ree_errors_test.error')
    error = klass.new

    expect(klass).to be_a(Class)
    expect(error).to be_a(ReeErrors::Error)
    expect(error.message).to eq('test error message')
    expect(error.code).to eq(:code)
    expect(error.type).to eq(:auth)
    expect(error.locale).to eq("ree_errors_test.error")
  }
end