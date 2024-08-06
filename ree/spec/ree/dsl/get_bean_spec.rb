# frozen_string_literal: true

package_require('accounts/commands/register_account_cmd')

RSpec.describe Accounts::RegisterAccountCmd do
  subject { described_class.new }

  it {
    Accounts::UsersRepo.init_store
    user = subject.call('John Doe', 'email@test.com', int: 1, string: 'string')

    expect(user.name).to eq('John Doe')
    expect(user.email).to eq('email@test.com')
  }

  it {
    Accounts::UsersRepo.init_store
    cmd = Accounts::RegisterAccountCmd.new
    user = cmd.call('John Doe', 'email@test.com', int: 1, string: 'string')

    expect(user.id).to eq(1)
    expect(user.name).to eq('John Doe')
    expect(user.email).to eq('email@test.com')
    expect(user.send(:user_states)).to be_a(Accounts::UserStates)
    expect(user.send(:function)).to eq(:function)
    expect(user.class::Entity).to eq(Accounts::Entity)
    expect(Accounts::RegisterAccountCmd::UserStates.value).to eq(:user_states)
  }
end
