# frozen_string_literal: true

RSpec.describe Ree::PackagesSchemaBuilder do
  subject do
    Ree::PackagesSchemaBuilder.new
  end

  it 'builder valid Packages.schema.json' do
    dir = sample_project_dir
    Ree.init(dir)

    File.write(File.join(dir, Ree::PACKAGES_SCHEMA_FILE), '', mode: 'w')

    schema = subject.call

    expect(schema['packages'].size > 0).to eq(true)
    expect(schema['gem_packages'].size).to eq(1)
  end
end