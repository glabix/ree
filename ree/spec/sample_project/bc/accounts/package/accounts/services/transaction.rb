class Accounts::Transaction
  include Ree::FnDSL

  fn :transaction do
    link :factory_users_repo
  end

  def call(&proc)
    yield
  end
end