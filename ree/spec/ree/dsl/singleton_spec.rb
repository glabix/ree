# frozen_string_literal: true

package_require('accounts/commands/register_account_cmd')

RSpec.describe :singleton do
  it {
    obj = Accounts::RegisterAccountCmd.new
    obj2 = Accounts::RegisterAccountCmd.new

    # singleton object should always product new instance if one injects one of it's deps
    obj3 = Accounts::RegisterAccountCmd.new(users_repo: Object.new)

    expect(obj.object_id).to eq(obj2.object_id)
    expect(obj.object_id).to_not eq(obj3.object_id)

    # factory singleton object
    expect(
      obj.instance_variable_get(:@transaction).instance_variable_get(:@factory_users_repo).object_id
    ).to eq(
      obj2.instance_variable_get(:@factory_users_repo).object_id
    )
  }
end