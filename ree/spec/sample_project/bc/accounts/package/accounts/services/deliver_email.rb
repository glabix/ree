class Accounts::DeliverEmail
  include Ree::FnDSL

  fn :deliver_email

  # contract(String, String => nil)
  def call(to:, body:)
  end
end