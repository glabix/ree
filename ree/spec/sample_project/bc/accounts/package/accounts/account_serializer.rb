class Accounts::AccountSerializer
  include Ree::BeanDSL

  bean :account_serializer do
    factory :build
  end

  def build
    Serializer
  end

  class Serializer
    class << self
      def call(account)
        {
          id: account.id,
          name: account.name
        }
      end
    end
  end
end