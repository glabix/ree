RSpec.describe Ree::CLI::IndexPackage do
  subject { described_class }

  let(:project_dir) { sample_project_dir }
  let(:package_name) { :accounts }
  
  context "run" do
    it "generates valid package index JSON" do
      result = subject.run(
        package_name: package_name,
        project_path: project_dir
      )

      expect(result).to_not be(nil)
      expect {
        JSON.parse(result)
      }.to_not raise_error

      parsed_result = JSON.parse(result)
      expect(parsed_result["package_schema"]).to_not be(nil)
      expect(parsed_result["classes"]).to_not be(nil)
      expect(parsed_result["objects"]).to_not be(nil)
    end
  end
end
