ENV['accounts.string_var'] = 'string'
ENV['accounts.integer_var'] = 'integer'

module Accounts
  include Ree::PackageDSL

  package do
    tags       ['account']

    depends_on :clock
    depends_on :roles
    depends_on :errors
    depends_on :test_utils
    depends_on :hash_utils

    env_var 'accounts.string_var'
    env_var 'accounts.integer_var'

    default_links do
      # link :time, from: :clock
    end

    preload(
      test: [
        :register_account_cmd,
        :build_user
      ]
    )
  end
end
