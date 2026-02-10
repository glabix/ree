# frozen_string_literal: true

class Ree::BenchmarkMethodPlugin
  def self.active?
    Ree.benchmark_mode?
  end

  def initialize(method_name, is_class_method, target)
    @method_name = method_name
    @is_class_method = is_class_method
    @target = target
  end

  def call
    return nil unless @method_name == :call && ree_fn?

    config = @target.instance_variable_get(:@__ree_benchmark_config)
    benchmark_name = build_benchmark_name

    if config
      build_entry_point_wrapper(benchmark_name, config)
    else
      build_collector_wrapper(benchmark_name)
    end
  end

  private

  def build_entry_point_wrapper(benchmark_name, config)
    output_proc = config[:output] || ->(res) { $stdout.puts(res) }
    deep = config.fetch(:deep, true)
    hide_ree_lib = config.fetch(:hide_ree_lib, true)
    once = config.fetch(:once, false)
    benchmark_done = false

    Proc.new do |instance, next_layer, *args, **kwargs, &block|
      if Ree::BenchmarkTracer.active?
        Ree::BenchmarkTracer.collect(benchmark_name) do
          next_layer.call(*args, **kwargs, &block)
        end
      elsif once && benchmark_done
        Ree::BenchmarkTracer.collect(benchmark_name) do
          next_layer.call(*args, **kwargs, &block)
        end
      else
        benchmark_done = true if once
        Ree::BenchmarkTracer.trace(benchmark_name, output_proc: output_proc, deep: deep, hide_ree_lib: hide_ree_lib) do
          next_layer.call(*args, **kwargs, &block)
        end
      end
    end
  end

  def build_collector_wrapper(benchmark_name)
    Proc.new do |instance, next_layer, *args, **kwargs, &block|
      Ree::BenchmarkTracer.collect(benchmark_name) do
        next_layer.call(*args, **kwargs, &block)
      end
    end
  end

  def build_benchmark_name
    pkg = @target.instance_variable_get(:@__ree_package_name)
    obj = @target.instance_variable_get(:@__ree_object_name)

    base = if pkg && obj
      "#{pkg}/#{obj}"
    else
      @target.name || @target.to_s
    end

    @method_name == :call ? base : "#{base}##{@method_name}"
  end

  def ree_fn?
    pkg = @target.instance_variable_get(:@__ree_package_name)
    obj = @target.instance_variable_get(:@__ree_object_name)
    return false unless pkg && obj

    facade = Ree.container.packages_facade
    return false unless facade.has_object?(pkg, obj)

    facade.get_object(pkg, obj).fn?
  end
end
