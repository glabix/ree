# frozen_string_literal: true

RSpec.describe Ree::ShadowLoader do
  it {
    # Ree.preload_for(:production) # overwrite preoload for test

    # Ree.init(shadow_load_project_dir)
    
    
    # require "#{sample_project_dir}/bc/accounts/package/background_worker"
    Ree.set_dev_mode
    Ree.load_package(:accounts)

    build_user_object =  Ree.container.packages_facade.load_package_object(:accounts, :build_user)
    # build_user_object.set_as_compiled(false)

    pp Accounts::BuildUser
    Accounts.send(:remove_const, :BuildUser) if Accounts.const_defined?(:BuildUser)

    expect{ Accounts::BuildUser }.to raise_error(NameError, /uninitialized/)

    Ree.enable_shadow_load

    # build_user_object.set_as_compiled(false)
    # build_user_object.instance_variable_set(:@loaded, false)

    acc_pack = Ree.container.packages_facade.get_package(:accounts)
    acc_pack.remove_object(:build_user)

    expect{ Accounts::BuildUser }.to raise_error(NameError, /class not found/)


    Ree.disable_shadow_load

    pp Accounts::BuildUser
    expect{ Accounts::BuildUser }.to raise_error(NameError)
  }
end
