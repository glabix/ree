RSpec.describe Ree::CLI::Indexing::IndexFile do
  subject { described_class }

  let(:project_dir) { sample_project_dir }
  let(:object_path) { "bc/accounts/package/accounts/entities/user.rb"}

  context "run" do
    xit "generates valid file index JSON" do
      result = subject.run(
        file_path: object_path,
        project_path: project_dir
      )

      expect(result).to_not be(nil)
      expect {
        JSON.parse(result)
      }.to_not raise_error
    end
  end
end
