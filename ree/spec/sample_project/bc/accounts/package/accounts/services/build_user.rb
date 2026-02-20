class Accounts::BuildUser
  include Ree::FnDSL

  fn :build_user do
    link :user_states
    link :raise_error, from: :errors
    link :time, from: :clock
    link :users_repo
    import -> { User }
  end

  InvalidDomainErr = Class.new(ArgumentError)
  EmailTakenErr = Class.new(ArgumentError)

  ALLOWED_DOMAINS = 'test.com'

  contract(String, String => User).throws(InvalidDomainErr, EmailTakenErr)
  def call(name, email)
    validate_email(email)

    User.new(
      1,
      name,
      email,
      user_states.inactive,
      time.now
    )
  end

  private

  def validate_email(email)
    if !ALLOWED_DOMAINS.include?(email.split('@').last)
      raise_error(InvalidDomainErr)
    end

    existing_user = users_repo.find_by_email(email)

    if existing_user
      raise_error(EmailTakenErr)
    end
  end
end