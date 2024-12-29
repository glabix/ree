# frozen_string_literal: true

require 'pathname'

class Ree::Package
  attr_reader :schema_version, :name, :schema_rpath, :entry_rpath,
              :module, :tags, :preload, :default_links, :gem_name

  def initialize(schema_version, name, entry_rpath, gem_name = nil)
    @schema_version = schema_version
    @name = name
    @schema_rpath = nil
    @entry_rpath = entry_rpath
    @objects_store = {}
    @deps_store = {}
    @env_vars_store = {}
    @entry_loaded = false
    @schema_loaded = false
    @loaded = false
    @tags = []
    @preload = {}
    @preloaded = false
    @gem_name = gem_name
  end

  def set_default_links(&block)
    @default_links = block; self
  end

  # @param [Bool] val
  def set_preloaded(val)
    @preloaded = val; self
  end

  def preloaded?
    @preloaded
  end

  # @param [String] val
  def set_schema_version(val)
    @schema_version = val; self
  end

  # @param [String] val
  def set_entry_rpath(val)
    @entry_rpath = val; self
  end

  # @param [ArrayOf[String]] list
  def set_tags(list)
    @tags = (@tags + list).map(&:to_s).uniq; self
  end

  # @param [String] val
  def set_schema_rpath(val)
    @schema_rpath = val; self
  end

  def reset
    @entry_loaded = false
    @schema_loaded = false
    @loaded = false
    @deps_store = {}
    @env_vars_store = {}
    @preload = {}
  end

  def set_preload(val)
    @preload = val; self
  end

  def loaded?
    @loaded
  end

  def set_loaded
    @loaded = true
  end

  def set_entry_loaded
    @entry_loaded = true
  end

  def set_schema_loaded
    @schema_loaded = true
  end

  def entry_loaded?
    @entry_loaded
  end

  def schema_loaded?
    @schema_loaded
  end

  def dir
    @dir ||= @entry_rpath ? Pathname.new(@entry_rpath).dirname.parent.to_s : nil
  end

  def gem?
    !!@gem_name
  end

  # @param [Module] mod
  def set_module(mod)
    @module = mod; self
  end

  # @list [ArrayOf[Ree::PackageDepsSchema]]
  def set_deps(list)
    list.each do |item|
      @deps_store[item.name] = item
    end
  end

  def deps
    @deps_store.values
  end

  # @param [Ree::PackageDep] dep
  def set_dep(dep)
    old = @deps_store[dep.name]
    @deps_store[dep.name] = dep
    old
  end

  # @param [Symbol] name
  def get_dep(name)
    @deps_store[name]
  end

  # @param [ArrayOf[Ree::PackageEnvVar]] list
  def set_env_vars(list)
    list.each do |item|
      @env_vars_store[item.name] = item
    end
  end

  def env_vars
    @env_vars_store.values
  end

  # @param [Ree::PackageEnvVar] var
  def set_env_var(var)
    old = @env_vars_store[var.name]
    @env_vars_store[var.name] = var
    old
  end

  # @param [String] name
  def get_env_var(name)
    @env_vars_store[name]
  end

  # @param [Ree::Object] object
  # @return [Nilor[Ree::Object]] Previous object version
  def set_object(object)
    if object.package_name != @name
      raise Ree::Error.new("package should only include objects from the same package")
    end

    existing = @objects_store[object.name]
    return existing if existing

    @objects_store[object.name] = object
  end

  # @param [Symbol] name
  # @return [nil]
  def remove_object(name)
    if @objects_store[name]
      @objects_store.delete(name)
    end

    nil
  end

  # @param [Symbol] name
  # @return [Nilor[Ree::Object]]
  def get_object(name)
    @objects_store[name]
  end

  def objects
    @objects_store.values.flatten
  end
end