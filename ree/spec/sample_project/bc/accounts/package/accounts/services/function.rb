class Accounts::Function
  include Ree::FnDSL

  fn :function

  def call
    :function
  end
end