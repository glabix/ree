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
    config = @target.instance_variable_get(:@__ree_benchmark_config)

    if @method_name == :call
      if config
        wrap_as_entry_point(config)
      else
        wrap_as_collector
      end
    end
  end

  private

  def wrap_as_entry_point(config)
    alias_target = @is_class_method ? eigenclass : @target
    method_name = @method_name
    method_alias = :"__benchmark_#{method_name}"

    return if alias_target.method_defined?(method_alias)

    alias_target.alias_method(method_alias, method_name)

    benchmark_name = build_benchmark_name
    output_proc = config[:output] || -> (res) { $stdout.puts(res) }
    deep = config.fetch(:deep, true)
    once = config.fetch(:once, false)
    benchmark_done = false

    alias_target.define_method(method_name) do |*args, **kwargs, &block|
      if once && benchmark_done
        Ree::BenchmarkTracer.collect(benchmark_name) do
          send(method_alias, *args, **kwargs, &block)
        end
      else
        benchmark_done = true if once
        Ree::BenchmarkTracer.trace(benchmark_name, output_proc: output_proc, deep: deep) do
          send(method_alias, *args, **kwargs, &block)
        end
      end
    end
  end

  def wrap_as_collector
    alias_target = @is_class_method ? eigenclass : @target
    method_name = @method_name
    method_alias = :"__benchmark_#{method_name}"

    return if alias_target.method_defined?(method_alias)

    alias_target.alias_method(method_alias, method_name)

    benchmark_name = build_benchmark_name

    alias_target.define_method(method_name) do |*args, **kwargs, &block|
      Ree::BenchmarkTracer.collect(benchmark_name) do
        send(method_alias, *args, **kwargs, &block)
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

  def eigenclass
    class << @target; self; end
  end
end
