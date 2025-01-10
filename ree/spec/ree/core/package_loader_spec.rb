# frozen_string_literal: true

RSpec.describe Ree::PackageLoader do
  subject do
    Ree::PackageLoader.new
  end

  it 'loads package objects' do
    expect{ Documents::CreateDocumentCmd }.to raise_error(NameError)

    package = Ree.container.packages_facade.get_loaded_package(:documents)

    # TODO move all specs to facade specs
    loader = Ree::PackageLoader.new(Ree.container.packages_facade.packages_store)

    loaded_package = loader.load_entire_package(package.name)

    expect{ Documents::CreateDocumentCmd }.not_to raise_error
  end

  it "loads dependency objects" do
    package = Ree.container.packages_facade.get_loaded_package(:documents)

    loader = Ree::PackageLoader.new(Ree.container.packages_facade.packages_store)

    loaded_package = loader.load_entire_package(package.name)

    expect{ Accounts::DeliverEmail }.not_to raise_error
  end

  it "loads gems dependency objects" do
    package = Ree.container.packages_facade.get_loaded_package(:documents)

    loader = Ree::PackageLoader.new(Ree.container.packages_facade.packages_store)

    loaded_package = loader.load_entire_package(package.name)

    expect{ HashUtils::Except }.not_to raise_error
  end
end