RSpec.configure do |config|
  config.extend Ree::RSpecLinkDSL

  config.before :each do
    reset_mapper_factory(self)
  end
end

def reset_mapper_factory(mod)
  mod = Object.const_get(self.class.to_s.split("::").first)
  mod.instance_variable_set(:@mapper_factory, nil)
end