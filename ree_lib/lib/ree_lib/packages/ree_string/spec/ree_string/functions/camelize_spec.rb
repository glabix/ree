# frozen_string_literal: true

RSpec.describe :camelize do
  link :camelize, from: :ree_string

  it {
    expect(
      camelize('active_model')
    ).to eq("ActiveModel")

    expect(
      camelize('active_model', uppercase_first_letter: false)
    ).to eq("activeModel")

    expect(
      camelize('active_model/errors')
    ).to eq("ActiveModel::Errors")

    expect(
      camelize('active_model/errors', uppercase_first_letter: false)
    ).to eq("activeModel::Errors")

    expect(
      camelize('active_http', acronyms: {'http' => 'HTTP'})
    ).to eq("ActiveHTTP")

    expect(
      camelize('http_get', acronyms: {'get' => 'GET', 'http' => 'HTTP'})
    ).to eq("HTTPGET")
  }
end