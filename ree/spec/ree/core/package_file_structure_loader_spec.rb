# frozen_string_literal: true

RSpec.describe Ree::PackageFileStructureLoader do
  subject do
    Ree::PackageFileStructureLoader.new
  end

  # TODO rewrite specs, make idempotent
  # right now it violates other spec loading process
  xit 'loads valid package' do
    package = Ree.container.packages_facade.get_package(:documents)
    package.reset

    loaded_package = subject.call(package)

    expect(loaded_package.name).to eq(:documents)
    expect(loaded_package.objects.size).to eq(2)
  end

  xit 'raises errors on duplicates' do
    package = Ree.container.packages_facade.get_package(:documents)
    package.reset

    duplicate_file_path = File.join(sample_project_dir, package.dir, "package/documents/services/create_document_cmd.rb")
    FileUtils.mkdir_p(File.dirname(duplicate_file_path))
    FileUtils.touch(duplicate_file_path)

    expect {
      subject.call(package)
    }.to raise_error(Ree::Error)
  ensure
    FileUtils.remove_file(duplicate_file_path)
  end
end