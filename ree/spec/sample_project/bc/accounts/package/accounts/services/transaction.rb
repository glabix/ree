class Accounts::Transaction
  include Ree::FnDSL

  fn :transaction do
    link :factory_users_repo
    with_caller
  end

  def call(&proc)
    get_caller
    yield
  end
end