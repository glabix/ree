# frozen_string_literal = true

package_require('ree_logger/beans/logger')

RSpec.describe :logger do
  link :logger, from: :ree_logger

  it {
    logger.info('hello world')
  }
end