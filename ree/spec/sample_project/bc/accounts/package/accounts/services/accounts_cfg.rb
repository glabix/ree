class Accounts::AccountsCfg
  include Ree::BeanDSL

  bean :accounts_cfg do
    factory :build
  end

  def build
    Config.new
  end

  class Config
    def initialize
      @db_name = ENV.fetch('accounts.db_name')
    end
    
    def env
      'test'
    end
  end
end