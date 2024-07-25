class Accounts::RegisterAccountCmd
  include Ree::FnDSL

  class UserStates
    class << self
      def value
        :user_states
      end
    end
  end

  fn :register_account_cmd do
    singleton

    link :build_user, import: -> { User }
    link :except, from: :hash_utils
    link :factory_users_repo
    link :transaction, target: :both
    link :user_states, import: -> { UserStates.as(States) }
    link :users_repo
    link :welcome_email
  end

  transaction do
    user_states
  end

  ValidationErr = Class.new(ArgumentError)

  doc("Register user and send welcome email")
  contract(String, String, SplatOf[Any], Kwargs[int: Integer, test: String], Ksplat[string?: String], Optblock => User).throws(ValidationErr)
  def call(name, email = nil, *args, int:, test: '1', **kwargs, &proc)
    transaction do
      attrs = {
        name: name,
        email: email,
        test: test
      }

      # example of usage of linked object from gem package
      except(attrs, :test)

      user = build_user(name, email)
      users_repo.put(user)

      if false
        raise ValidationErr, 'validation error'
      end

      if user.state == States.inactive
        factory_users_repo.put(user)
        reloaded_user = factory_users_repo.find(user.id)
        reloaded_user.id
      end

      welcome_email.deliver(user.id)

      user
    end
  end
end


