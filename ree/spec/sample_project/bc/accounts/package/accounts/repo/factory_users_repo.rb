
class Accounts::FactoryUsersRepo
  include Ree::BeanDSL

  bean :factory_users_repo do
    singleton
    factory :build
  end

  def build
    Repo.new
  end

  class Repo
    def initialize
      @user_store = []
    end

    def put(entity)
      @user_store.push(entity)
    end

    def find(id)
      @user_store.detect { |_| _.id == id}
    end

    def find_by_email(email)
      @user_store.detect { |_| _.email == email }
    end
  end
end