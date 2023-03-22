# frozen_string_literal: true

package_require('ree_validator/functions/validate_password')

RSpec.describe ReeValidator::ValidatePassword do
  link :validate_password, from: :ree_validator

  context 'valid password' do
    it {
      password = validate_password('Password1!')
      no_digit_pass = validate_password('Password!')

      expect(password).to eq(true)
      expect(no_digit_pass).to eq(true)
    }
  end

  context 'valid password with options' do
    it {
      short_password = validate_password('Pass1!', min_length: 5)
      expect(short_password).to eq(true)

      long_password = validate_password('Password1!' * 2, max_length: 20)
      expect(long_password).to eq(true)

      digit_password = validate_password('Pass111!', digit_count: 3)
      expect(digit_password).to eq(true)

      lowercase_char_password = validate_password('Passs!', lowercase_char_count: 4)
      expect(lowercase_char_password).to eq(true)

      uppercase_char_password = validate_password('PPPasword!', uppercase_char_count: 3)
      expect(uppercase_char_password).to eq(true)

      special_symbol_password = validate_password('Password!#$%', special_symbol_count: 4)
      expect(special_symbol_password).to eq(true)
    }
  end

  context 'invalid password' do
    it {
      expect {
        validate_password('Pass!', min_length: 6)
      }.to raise_error(
        ReeValidator::ValidatePassword::PasswordErr,
        'password length can not be less than 6'
      )

      expect {
        validate_password('Password1!' * 2, max_length: 10)
      }.to raise_error(
        ReeValidator::ValidatePassword::PasswordErr,
        'password length can not be more than 10'
      )

      expect{
        validate_password('Password1!', uppercase_char_count: 3)
      }.to raise_error(
        ReeValidator::ValidatePassword::PasswordErr,
        'number of uppercase characters should be more than 3'
      )

      expect{
        validate_password('Pas!', lowercase_char_count: 3)
      }.to raise_error(
        ReeValidator::ValidatePassword::PasswordErr,
        'number of lowercase characters should be more than 3'
      )

      expect{
        validate_password('Password1!', digit_count: 3)
      }.to raise_error(
        ReeValidator::ValidatePassword::PasswordErr,
        'number of digits should be more than 3'
      )

      expect{
        validate_password('Password1!', special_symbol_count: 3)
      }.to raise_error(
        ReeValidator::ValidatePassword::PasswordErr,
        'number of special symbols should be more than 3'
      )
    }
  end
end