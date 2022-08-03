# frozen_string_literal: true

RSpec.describe Ree::PackagesSchemaLoader do
  subject do
    Ree::PackagesSchemaLoader.new
  end

  it 'loads valid file' do
    result = subject.call(File.join(__dir__, 'samples/packages_schemas/valid.packages.json'))
    expect(result.packages.size).to eq(5)
  end

  it 'does not load file with duplicates' do
    expect {
      subject.call(File.join(__dir__, 'samples/packages_schemas/duplicate_names.packages.json'))
    }.to raise_error(Ree::Error)
  end

  it 'does not load empty name json ' do
    expect {
      subject.call(File.join(__dir__, 'samples/packages_schemas/empty_name.packages.json'))
    }.to raise_error(Ree::Error)
  end
end