class Accounts::User < Struct.new(:id, :name, :email, :state, :created_at)
  include Ree::LinkDSL

  link :user_states, import: -> { UserStates }
  link 'accounts/entities/entity', -> { Entity }
  link :function, from: :accounts
  link :transaction

  # testing link
  new.instance_exec do
    transaction do
      user_states
    end
  end
end