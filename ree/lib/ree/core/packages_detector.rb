# frozen_string_literal  = true

require 'pathname'

class Ree::PackagesDetector
  # @param [String] dir Packages root dir
  # @return [ArrayOf[{name: String, entry_path: String, package_schema_path: String, gem_name: Nilor[String]}]]
  def call(dir, gem_name = nil)
    if !Dir.exists?(dir)
      raise Ree::Error.new("dir does not exist: #{dir}", :invalid_dir)
    end

    files = File.join(dir, "**/", Ree::PACKAGE_SCHEMA_FILE)
    names = {}

    Dir[files].map do |file|
      package_schema_path = Pathname
        .new(file)
        .relative_path_from(Pathname.new(dir))
        .to_s

      name = package_schema_path.split('/')[-2]
      entry_path = Ree::PathHelper.package_entry_path(package_schema_path)

      if !File.exists?(File.join(dir, entry_path))
        Ree.logger.error("Entry file does not exist for '#{name}' package: #{entry_path}")
      end

      if names.has_key?(name)
        raise Ree::Error.new("package '#{name}' has duplicate defintions.\n\t1) #{names[name]},\n\t2) #{entry_path}", :duplicate_package)
      end

      names[name] = entry_path

      {
        name: name.to_sym,
        entry_path: entry_path,
        package_schema_path: package_schema_path,
        gem_name: gem_name
      }
    end
  end
end