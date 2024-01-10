# frozen_string_literal: true

class Ree::SpecRunner::View
  def packages_menu(prepared_command_params)
    prepared_command_params
      .sort_by(&:package_path)
      .map { |x| " - #{x.package_name} (#{x.spec_count} spec files)" }
      .join("\n")
  end

  def package_not_found_message(package_name, prepared_command_params)
    "Package #{package_name} not found! \nPossible packages:\n\n#{packages_menu(prepared_command_params)}"
  end

  def missing_specs_message(skipped_packages)
    "NO SPECS FOUND FOR PACKAGES: \n#{skipped_packages.map { |x| " - #{x}" }.join("\n")}\n\n"
  end

  def skipping_specs_message(skipped_packages)
    "FOLLOWING PACKAGES WERE SKIPPED BY .runignore FILE: \n#{skipped_packages.map { |x| " - #{x}" }.join("\n")}\n\n"
  end

  def specs_header_message
    "**** SPECS *****"
  end

  def no_specs_for_package(package_name)
    "Package #{package_name} has no specs to execute!"
  end
end
