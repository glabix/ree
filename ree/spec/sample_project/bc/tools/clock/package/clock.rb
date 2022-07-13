ENV['clock.string_var'] = 'string'
ENV['clock.int_var'] = 'int'

module Clock
  include Ree::PackageDSL

  package do
    tags ['wip']

    depends_on :test_utils

    env_var 'clock.string_var'
    env_var 'clock.int_var'
  end
end