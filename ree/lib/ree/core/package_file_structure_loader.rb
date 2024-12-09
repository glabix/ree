# frozen_string_literal: true

require 'pathname'

class Ree::PackageFileStructureLoader
  # @param [Nilor[Ree::Package]] existing_package Loaded package
  # @return [Ree::Package]
  def call(existing_package)
    root_dir = if existing_package && existing_package.gem?
      Ree.gem(existing_package.gem_name).dir
    else
      Ree.root_dir
    end

    pp existing_package
    pp root_dir

    existing_package
  end
end