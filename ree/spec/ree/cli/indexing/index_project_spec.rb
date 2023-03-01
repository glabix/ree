RSpec.describe Ree::CLI::IndexProject do
  subject { described_class }

  let(:project_dir) { sample_project_dir }
  
  context "run" do
    it "generates valid project index JSON" do
      result = subject.run(
        project_path: project_dir
      )

      expect(result).to_not be(nil)

      expect {
        JSON.parse(result)
      }.to_not raise_error

      parsed_result = JSON.parse(result)

      expect(parsed_result["packages_schema"]).to_not be(nil)
      expect(parsed_result["classes"]).to_not be(nil)
      expect(parsed_result["objects"]).to_not be(nil)
    end
  end
end
