class Accounts::WelcomeEmail
  extend Ree::BeanDSL

  bean :welcome_email do
    # link :perform_async
    link :users_repo
    link :deliver_email
  end

  # contract Num => nil
  def deliver(user_id)
    user = users_repo.find(user_id)

    body = %Q(
      welcome #{user.name}
    )

    deliver_email(
      to: user.email,
      body: user.email,
    )

    nil
  end

  # contract Num => nil
  def deliver_async(user_id)
  end
end