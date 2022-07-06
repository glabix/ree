require 'ree'
Ree.init(__dir__)

require 'rspec'
require_relative '../package/accounts'

RSpec.configure do |config|
  config.extend Ree::RSpecLinkDSL
end
