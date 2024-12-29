# frozen_string_literal: true

require 'set'
require 'pathname'

class Ree::PackageLoader
  def initialize()
    @loaded_paths = {}
  end

  def reset
    @loaded_paths = {}
  end

  def load_file(path, package_name)
    @loaded_paths[package_name] ||= {}
    return if @loaded_paths[package_name][path]
    @loaded_paths[package_name][path] = true

    Ree.logger.debug("load_file(:#{package_name}, '#{path}')")
    Kernel.require(path)
  end
end
