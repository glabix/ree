class Accounts::UserStates
  include Ree::BeanDSL

  bean :user_states

  class << self
    def active
      :active
    end

    def inactive
      :inactive
    end
  end

  def active
    :active
  end

  def inactive
    :inactive
  end
end