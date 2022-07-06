RSpec.describe Ree::CLI::GeneratePackagesSchema do
  subject { described_class }
  let(:project_dir) { sample_project_dir }

  context "run" do
    it "generates Packages.schema.json" do
      subject.run(project_dir)

      FileUtils.cd(project_dir) do
        ensure_exists(Ree::PACKAGES_SCHEMA_FILE)
      end
    end

    it "output path for packages schema" do
      output = with_captured_stdout {
        subject.run(project_dir)
      }

      expect(output).to include(Ree::PACKAGES_SCHEMA_FILE)
    end
  end
end
