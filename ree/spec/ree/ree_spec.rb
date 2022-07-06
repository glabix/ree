# frozen_string_literal: true

RSpec.describe Ree do
  it "has a version number" do
    expect(Ree::VERSION).not_to be nil
  end

  it "generates schemas for all packages" do
    expect {
      Ree.generate_schemas_for_all_packages
    }.not_to raise_error
  end

  it "generates schema for specific object" do
    package_require('accounts/commands/register_account_cmd')
    json = Ree.write_object_schema(:accounts, :register_account_cmd)
    sample = File.read(File.join(__dir__, 'samples', 'register_account_cmd.schema.json'))

    expect(json).to eq(sample)
  end
end
