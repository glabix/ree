# frozen_string_literal: true

RSpec.describe Ree::PathHelper do
  subject { Ree::PathHelper }

  it {
    result = subject.object_rpath('bc/accounts/schemas/accounts/object.schema.json')
    expect(result).to eq('bc/accounts/package/accounts/object.rb')
  }

  it {
    result = subject.object_schema_rpath('bc/accounts/package/accounts/object.rb')
    expect(result).to eq('bc/accounts/schemas/accounts/object.schema.json')
  }

  it {
    result = subject.package_entry_path('bc/accounts/Package.schema.json')
    expect(result).to eq('bc/accounts/package/accounts.rb')
  }
end
