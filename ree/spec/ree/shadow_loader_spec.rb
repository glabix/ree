# frozen_string_literal: true

RSpec.describe Ree::ShadowLoader do
  it {
    Ree.set_dev_mode
    Ree.load_package(:accounts)

    object_path = "#{sample_project_dir}/bc/accounts/package/accounts/services/build_user.rb"
    build_user_object =  Ree.container.packages_facade.load_package_object(:accounts, :build_user)

    Accounts.send(:remove_const, :BuildUser) if Accounts.const_defined?(:BuildUser)
    expect{ Accounts::BuildUser }.to raise_error(NameError, /uninitialized/)

    Ree.enable_shadow_load

    # check ShadowLoader raises custom error message if class was not found by ree loader
    expect{ Accounts::BuildUser }.to raise_error(NameError, /class not found/)

    # remove loaded object from package
    acc_pack = Ree.container.packages_facade.get_package(:accounts)
    acc_pack.remove_object(:build_user)
    Ree.container.packages_facade.package_loader.reset
    expect(
      Ree.container.packages_facade.package_loader.instance_variable_get(:@loaded_paths)
    ).to eq({})

    # check that ree tried to load the object
    expect{ Accounts::BuildUser }.to raise_error(Ree::Error)
    expect(
      Ree.container.packages_facade.package_loader.instance_variable_get(:@loaded_paths)
    ).to eq({ accounts: {object_path => true } })

    Ree.disable_shadow_load

    # check default error is restored
    expect{ Accounts::BuildUser }.to raise_error(NameError, /uninitialized/)

    # return constant not to break other tests
    load(object_path)
    acc_pack.set_object(build_user_object)
    expect{ Accounts::BuildUser }.not_to raise_error
  }
end
