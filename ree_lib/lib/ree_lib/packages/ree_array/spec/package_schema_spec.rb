RSpec.describe "ReeArray" do
  it "generates package schema" do
    packages_schema_path = Ree.locate_packages_schema(__dir__)
    packages_schema_dir = Pathname.new(packages_schema_path).dirname.to_s
    Ree.init(packages_schema_dir)

    package_name = Ree::StringUtils.underscore(self.class.description).to_sym

    Ree.load_package(package_name)
    write_package_call = Ree.container.packages_facade.write_package_schema(package_name)

    expect(write_package_call).to eq(nil)
  end
end
