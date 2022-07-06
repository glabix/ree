require 'set'

module Ree
  module CLI
    class SpecRunner
      attr_reader :packages_to_run

      class << self
        def run(path:, package_names:, spec_matcher:, tag_name:,
                with_children:, with_ancestors:, run_all: false)
          SpecRunner.new(
            package_names: package_names,
            spec_matcher: spec_matcher,
            tag_name: tag_name,
            with_children: with_children,
            with_ancestors: with_ancestors,
            path: path,
            run_all: run_all
          ).run
        end
      end

      def initialize(package_names:, spec_matcher:, tag_name:, with_children:,
                     with_ancestors:, run_all: false, path:, stdout: STDOUT)
        @package_names = package_names || []
        @packages_to_run = @package_names
        @spec_matcher = spec_matcher
        @tag_name = tag_name
        @with_children = with_children
        @with_ancestors = with_ancestors
        @run_all = run_all
        @path = path
        @stdout = stdout
      end

      def run
        schema_path = Ree.locate_packages_schema(@path)
        schema_dir = Pathname.new(schema_path).dirname.to_s

        Ree.init(schema_dir)

        unless non_existent_packages.empty?
          non_existent_packages.map do |pack|
            puts "Package #{pack} not found"
            @package_names.delete(pack)
          end
        end

        if @tag_name
          puts "Trying to find packages with tag \"#{@tag_name}\"..."

          tagged_packages = find_tagged_packages

          if tagged_packages.empty?
            puts "No packages found with tag #{@tag_name}"
          end

          @packages_to_run.push(*tagged_packages)
        end

        if @with_children
          children_packages = @package_names.map do |package_name|
            puts "Trying to find children packages for #{package_name}"

            find_children_packages(package_name)
          end

          @packages_to_run.push(*children_packages)
        end

        if @with_ancestors
          ancestors_packages = @package_names.map do |package_name|
            puts "Trying to find ancestors packages for #{package_name}"

            find_ancestors_packages(package_name)
          end

          @packages_to_run.push(*ancestors_packages)
        end

        if @run_all
          puts "Running specs for all packages..."

          @packages_to_run.push(*packages.map(&:name))
        end

        @packages_to_run = @packages_to_run.flatten.uniq

        if @packages_to_run.empty?
          puts "No packages found with specified options"
        end

        @packages_to_run.each do |package|
          ree_package = Ree.container.packages_facade.get_package(package)

          Ree::SpecRunner::Runner.new(
            path: Ree::PathHelper.project_root_dir(ree_package),
            package: package,
            spec_matcher: @spec_matcher,
            stdout: $stdout
          ).run
        end
      end

      private

      def project_packages(packages)
        packages.reject(&:gem?)
      end
      
      def non_existent_packages
        @package_names ? @package_names - packages.map(&:name) : []
      end

      def find_tagged_packages
        names = packages.map(&:name)

        names.select do |package_name|
          package = container.packages_facade.read_package_schema_json(package_name)
          package.tags.include?(@tag_name)
        end.compact
      end

      def find_children_packages(package_name)
        recursively_find_children_packages(package_name)
      end

      def find_ancestors_packages(package_name)
        recursively_find_ancestor_packages(package_name)
      end

      def container
        @container = Ree.container
      end

      def packages
        @packages ||=  project_packages(
          container.packages_facade.load_packages_schema.packages
        )
      end

      def packages_set
        @packages_set ||= Set.new(packages.map(&:name))
      end

      def recursively_find_children_packages(package_name, acc = [])
        package = container.load_package(package_name)

        unless acc.include?(package.name)
          acc << package.name
          
          package.deps.map(&:name).each do |pack|
            next if !packages_set.include?(pack)
            recursively_find_children_packages(pack, acc)
          end
        end

        acc
      end

      def recursively_find_ancestor_packages(package_name, all_packages: packages, acc: Set.new([package_name]), count: 0)
        parents = package_parents(package_name, all_packages)

        all_packages = all_packages.reject { |pack| parents.include?(pack.name) }
        return acc.to_a if parents.empty?

        parents.map { |pa| acc.add(pa) }

        parents.each do |parent|
          recursively_find_ancestor_packages(parent, all_packages: all_packages, acc: acc.flatten, count: count + 1).map { |e| acc.add(e) }
        end

        acc.to_a
      end

      def package_parents(package_name, packages)
        packages.map do |pack|
          package = container.load_package(pack.name)
          pack.name if package.deps.map(&:name).include?(package_name)
        end.compact
      end
    end
  end
end
