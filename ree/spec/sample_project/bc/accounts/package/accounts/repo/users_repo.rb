class Accounts::UsersRepo
  include Ree::BeanDSL

  bean :users_repo do
    after_init :setup
  end

  class << self
    def init_store
      @store = []
    end

    def store
      @store
    end
  end
  
  def store
    self.class.store
  end
  
  def setup
    self.class.init_store
    store = []
  end

  def put(entity)
    store.push(entity)
  end

  def find(id)
    store.detect { |_| _.id == id}
  end

  def find_by_email(email)
    store.detect { |_| _.email == email }
  end
end