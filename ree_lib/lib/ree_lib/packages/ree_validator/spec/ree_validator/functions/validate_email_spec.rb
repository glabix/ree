# frozen_string_literal: true

RSpec.describe :validate_email do
  link :validate_email, from: :ree_validator

  it {
    expect(
      validate_email('test@example.com', :email)
    ).to eq(true)

    expect {
      validate_email('test@example', :email)
    }.to raise_error(ReeValidator::ValidateEmail::InvalidEmailErr)

    expect {
      validate_email('test', :email)
    }.to raise_error(ReeValidator::ValidateEmail::InvalidEmailErr)
  }
end