# frozen_string_literal: true

RSpec.describe Ree::PackagesSchemaLocator do
  subject do
    Ree::PackagesSchemaLocator.new
  end

  it 'loads valid file' do
    path = File.expand_path(
      File.join(__dir__, '../../sample_project/bc/accounts')
    )

    result = subject.call(path)
    
    expect(result.include?(Ree::PACKAGES_SCHEMA_FILE)).to eq(true)
  end

  it 'raises error for invalid path' do
    expect {
      subject.call(__FILE__)
    }.to raise_error(Ree::Error)
  end
end