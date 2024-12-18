# frozen_string_literal: true

require 'pathname'

class Ree::PackagesDetector
  # @param [String] dir Packages root dir
  # @return [ArrayOf[{name: String, entry_path: String, package_schema_path: String, gem_name: Nilor[String]}]]
  def call(dir, gem_name = nil)
    if !Dir.exist?(dir)
      raise Ree::Error.new("dir does not exist: #{dir}", :invalid_dir)
    end

    names = {}
    packages = []

    # find by schema file
    files = File.join(dir, "**/", Ree::PACKAGE_SCHEMA_FILE)
    Dir[files].map do |file|
      package_schema_path = Pathname
        .new(file)
        .relative_path_from(Pathname.new(dir))
        .to_s

      name = package_schema_path.split('/')[-2]
      entry_path = Ree::PathHelper.package_entry_path(package_schema_path)

      if !File.exist?(File.join(dir, entry_path))
        Ree.logger.error("Entry file does not exist for '#{name}' package: #{entry_path}")
      end

      if names.has_key?(name)
        raise Ree::Error.new("package '#{name}' has duplicate defintions.\n\t1) #{names[name]},\n\t2) #{entry_path}", :duplicate_package)
      end

      names[name] = entry_path

      packages << {
        name: name.to_sym,
        entry_path: entry_path,
        package_schema_path: package_schema_path,
        gem_name: gem_name
      }
    end

    package_dirs = File.join(dir, "**/package")
    Dir[package_dirs].each do |package_dir|
      next unless File.directory?(package_dir)

      dir_path = Pathname.new(package_dir)
      name = dir_path.parent.basename.to_s

      next if names.has_key?(name)

      package_rel_path = dir_path.relative_path_from(dir)
      parent_rel_path = dir_path.parent.relative_path_from(dir)

      entry_path = Ree::PathHelper.package_entry_path(package_rel_path)

      names[name] = entry_path

      packages << {
        name: name.to_sym,
        entry_path: entry_path,
        package_schema_path: File.join(parent_rel_path, Ree::PACKAGE_SCHEMA_FILE),
        gem_name: gem_name
      }
    end

    packages
  end
end