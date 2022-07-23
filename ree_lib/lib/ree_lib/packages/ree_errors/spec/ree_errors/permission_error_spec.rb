package_require('ree_errors/permission_error')

RSpec.describe ReeErrors::PermissionError do
  it {
    klass = described_class.build(:code)
    error = klass.new('message')

    expect(klass).to be_a(Class)
    expect(error).to be_a(ReeErrors::Error)
    expect(error.message).to eq('message')
    expect(error.code).to eq(:code)
    expect(error.type).to eq(:permission)
    expect(error.locale).to eq(nil)
  }
end