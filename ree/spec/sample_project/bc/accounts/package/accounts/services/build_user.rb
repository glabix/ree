class Accounts::BuildUser
  include Ree::FnDSL

  fn :build_user do
    link :user_states, import: -> { UserStates }
    link :users_repo
    link :time, from: :clock
    link :raise_error, from: :errors
    link 'accounts/entities/user', -> { User }

    def_error(:not_found) { InvalidDomainErr }
    def_error(:validation) { EmailTakenErr["email taken"] }
  end

  ALLOWED_DOMAINS = 'google.com'

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
    if ALLOWED_DOMAINS.include?(email.split('@').last)
      raise_error(InvalidDomainErr)
    end

    existing_user = users_repo.find_by_email(email)

    if existing_user
      raise_error(EmailTakenErr)
    end
  end
end