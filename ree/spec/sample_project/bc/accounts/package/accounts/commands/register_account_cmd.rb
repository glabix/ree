class Accounts::RegisterAccountCmd
  include Ree::FnDSL

  fn :register_account_cmd do
    singleton
    
    link :transaction
    link :build_user, import: -> { User & UserStates.as(States) }
    link :users_repo, methods: [:put]
    link :factory_users_repo, methods: [:put]
    link :welcome_email
    link :except, from: :hash_utils

    def_error { ValidationErr }
  end

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
