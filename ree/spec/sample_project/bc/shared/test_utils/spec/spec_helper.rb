require 'ree'
Ree.init(__dir__)

require 'rspec'

RSpec.configure do |config|
  config.extend Ree::RSpecLinkDSL
end
