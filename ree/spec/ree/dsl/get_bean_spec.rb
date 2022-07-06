# frozen_string_literal  = true

package_require('accounts/commands/register_account_cmd')

RSpec.describe Accounts::RegisterAccountCmd do
  subject { described_class.new }

  it {
    user = subject.call('John Doe', 'email@test.com', int: 1, string: 'string')

    expect(subject.frozen?).to eq(true)
    expect(user.name).to eq('John Doe')
    expect(user.email).to eq('email@test.com')
  }

  class TestRepo
    attr_reader :store

    def initialize
      @store = []
    end
    
    def put(entity)
      @store.push(entity)
    end

    def find(id)
      @store.detect { |_| _.id == id}
    end

    def find_by_email(email)
      @store.detect { |_| _.email == email }
    end

    def all
      @store
    end
  end
  
  it {
    users_repo = TestRepo.new
    cmd = Accounts::RegisterAccountCmd.new
    cmd = Accounts::RegisterAccountCmd.new(users_repo: users_repo)

    user = cmd.call('John Doe', 'email@test.com', int: 1, string: 'string')

    expect(users_repo.store.size).to eq(1)
    expect(user.id).to eq(1)
    expect(user.name).to eq('John Doe')
    expect(user.email).to eq('email@test.com')
  }
end
