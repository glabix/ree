class Accounts::User < Struct.new(:id, :name, :email, :state, :created_at)
  include Ree::LinkDSL

  link :user_states, import: -> { UserStates }
  link 'accounts/entities/entity', -> { Entity }
  link :function, from: :accounts
end