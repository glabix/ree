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
end
