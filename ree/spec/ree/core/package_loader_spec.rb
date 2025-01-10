# frozen_string_literal: true

RSpec.describe Ree::PackageLoader do
  subject do
    Ree::PackageLoader.new
  end

  it 'loads package objects' do
    pp package = Ree.container.packages_facade.get_loaded_package(:documents)

    loaded_package = subject.call(package)

    expect(Documents::CreateDocumentCmd).not_to raise_error
  end

  # it "loads dependency objects" do
  # it "loads gems dependency objects" do
end