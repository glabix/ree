# frozen_string_literal: true

require 'pathname'

class Ree::Container
  class << self
    SEMAPHORE = Mutex.new
    private_constant :SEMAPHORE

    # singleton
    def instance
      SEMAPHORE.synchronize do
        @instance ||= begin
          self.new
        end
      end

      @instance
    end
  end

  include Ree::Args

  MOUNT_AS = [:fn, :object]

  attr_reader :packages_facade

  def initialize
    @packages_facade = Ree::PackagesFacade.new
    @object_compiler = Ree::ObjectCompiler.new(@packages_facade)
  end

  # @param [Ree::Package] package
  # @param [Symbol] object_name
  def compile(package, object_name)
    compile_object("#{package.name}/#{object_name}")
  end

  # @param [String] name_with_package
  # @return [Ree::Object]
  def compile_object(name_with_package)
    check_arg(name_with_package, :name_with_package, String)

    list = name_with_package.to_s.split('/')

    name = nil
    package_name = nil

    if list.size == 2
      package_name = list.first.to_sym
      name = list.last.to_sym
    else
      raise Ree::Error.new("'package/name' definition should be used to load object", :invalid_dsl_usage)
    end

    @packages_facade.get_loaded_package(package_name)
    @packages_facade.load_package_object(package_name, name)

    @object_compiler.call(package_name, name)
  end

  # @param [Symbol] package_name
  # @return [Ree::Package]
  def load_package(package_name)
    @packages_facade.read_package_structure(package_name)
  end
end