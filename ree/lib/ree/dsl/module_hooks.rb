# frozen_string_literal  = true

module Kernel
  def package(&proc)
    path = caller[0].split(':').first

    dsl = Ree::PackageDsl.new(
      Ree.container.packages_facade, self, path
    )

    dsl.instance_exec(&proc) if block_given?

    return if dsl.package.preloaded?
    dsl.package.set_preloaded(true)

    dsl.package.preload.each do |env, list|
      next if !Ree.preload_for?(env)

      list.each do |object_name|
        Ree.container.compile_object(
          "#{dsl.package.name}/#{object_name}",
        )
      end
    end
  end
end