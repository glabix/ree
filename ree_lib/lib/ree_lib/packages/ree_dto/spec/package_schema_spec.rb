RSpec.describe "ReeDto" do
  it "generates package schema" do
    require 'fileutils'

    packages_schema_path = Ree.locate_packages_schema(__dir__)
    packages_schema_dir = Pathname.new(packages_schema_path).dirname.to_s

    FileUtils.cd packages_schema_dir do
      expect(
        system("bundle exec ree gen.package_json ree_dto --silence")
      ).to eq(true)
    end
  end
end
