# frozen_string_literal: true

def package_require(path)
  list = path.split('/')
  package_name = list.shift.to_sym
  packages_facade = Ree.container.packages_facade
  package = packages_facade.get_package(package_name)

  return false if package.dir.nil?

  path = File.join(
    Ree::PathHelper.abs_package_module_dir(package), list.join('/')
  )

  if !File.exist?(path)
    path = path + '.rb'
  end

  if !File.exist?(path)
    raise Ree::Error.new("file not found: #{path}")
  end

  Ree.logger.debug("package_require(#{path})")
  packages_facade.load_package_entry(package_name)
  packages_facade.load_file(path, package_name)
end

def package_file_exists?(path)
  list = path.split('/')
  package_name = list.shift.to_sym
  packages_facade = Ree.container.packages_facade
  package = packages_facade.get_package(package_name)

  return false if package.dir.nil?

  path = File.join(
    Ree::PathHelper.abs_package_module_dir(package), list.join('/')
  )

  return true if File.exist?(path)

  path = path + '.rb'
  File.exist?(path)
end
