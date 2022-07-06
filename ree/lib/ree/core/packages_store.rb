# frozen_string_literal  = true

class Ree::PackagesStore
  attr_reader :ree_version
  
  def initialize(ree_version = Ree::VERSION)
    @ree_version = ree_version
    @store = {}
  end

  def set_ree_version(val)
    @ree_version = val; self
  end

  def packages
    @store.values
  end

  # @param [Symbol] name
  # @return [Ree::Package]
  def get(name)
    @store[name]
  end

  # @param [Ree::Package] package
  def add_package(package)
    existing = get(package.name)
    return existing if existing
    
    @store[package.name] = package
  end
end