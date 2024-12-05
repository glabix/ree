# frozen_string_literal: true

RSpec.describe Ree::ShadowLoader do
  it {
    Ree.preload_for(:production) # overwrite preoload for test

    require_relative '../sample_project/bc/roles/package/roles.rb'

    expect{ Accounts::RegisterAccountCmd }.to raise_error(NameError)

    Ree.enable_shadow_load

    expect{ Accounts::DeliverEmail }.not_to raise_error

    Ree.disable_shadow_load

    expect{ Accounts::RegisterAccountCmd }.to raise_error(NameError)

  }
end