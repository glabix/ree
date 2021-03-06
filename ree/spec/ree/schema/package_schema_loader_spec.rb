# frozen_string_literal: true

RSpec.describe Ree::PackageSchemaLoader do
  subject do
    Ree::PackageSchemaLoader.new
  end

  it 'loads valid file' do
    package = subject.call(File.join(__dir__, 'samples/package_schemas/valid.package.json'))
    expect(package.ree_version).to eq("1.2.3")
    expect(package.name).to eq(:accounts)
    expect(package.entry_rpath).to eq("package/accounts.rb")
    expect(package.deps.size).to eq(2)
    expect(package.env_vars.size).to eq(2)
    expect(package.objects.size).to eq(2)
  end

  it 'does not load file with duplicates' do
    expect {
      subject.call(File.join(__dir__, 'samples/package_schemas/duplicate_names.package.json'))
    }.to raise_error(Ree::Error)
  end

  it 'does not load empty name json ' do
    expect {
      subject.call(File.join(__dir__, 'samples/package_schemas/empty_name.package.json'))
    }.to raise_error(Ree::Error)
  end
end