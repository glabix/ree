# frozen_string_literal: true

RSpec.describe :underscore do
  link :underscore, from: :ree_string

  it {
    expect(underscore("HTMLTidy")).to eq("html_tidy")
    expect(underscore("ActiveModel")).to eq("active_model")
    expect(underscore("ActiveModel::Errors")).to eq("active_model/errors")
    expect(underscore("NRIS", acronyms: ['NRI'])).to eq("nri_s")

    data = {
      "NRI" => "nri",
      "Product" => "product",
      "SpecialGuest" => "special_guest",
      "ApplicationController" => "application_controller",
      "Area51Controller" => "area51_controller",
      "AppCDir" => "app_c_dir",
      "Accountsv2N2Test" => "accountsv2_n2_test",
    }

    data.each do |k, v|
      expect(underscore(k)).to eq(v)
    end
  }
end