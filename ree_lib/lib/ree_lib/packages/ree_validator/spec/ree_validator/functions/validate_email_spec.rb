# frozen_string_literal: true

RSpec.describe :validate_email do
  link :validate_email, from: :ree_validator

  it {
    expect(
      validate_email('test@example.com')
    ).to eq(true)
  }

  it {
    expect {
      validate_email('test@example')
    }.to raise_error(ReeValidator::ValidateEmail::InvalidEmailErr)
  }

  it {
    expect {
      validate_email('test', Class.new(StandardError))
    }.to raise_error(StandardError)
  }
end