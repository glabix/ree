# frozen_string_literal: true

package_require('accounts/account_serializer')

RSpec.describe Accounts::AccountSerializer do
  it {
    expect(described_class.new).to eq(Accounts::AccountSerializer::Serializer)
  }
end