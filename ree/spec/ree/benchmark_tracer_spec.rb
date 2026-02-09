# frozen_string_literal: true

RSpec.describe Ree::BenchmarkTracer do
  describe '.trace' do
    after do
      Thread.current[:ree_benchmark_tracer] = nil
    end

    it 'prints tree for a single call' do
      output = with_captured_stdout do
        Ree::BenchmarkTracer.trace('test_package/test_fn') { 42 }
      end

      expect(output).to match(/^test_package\/test_fn \(\d+\.\d+ms\)\n$/)
    end

    it 'returns the block result' do
      result = nil

      with_captured_stdout do
        result = Ree::BenchmarkTracer.trace('test_package/test_fn') { 42 }
      end

      expect(result).to eq(42)
    end

    it 'prints nested call tree with indentation' do
      output = with_captured_stdout do
        Ree::BenchmarkTracer.trace('parent/fn') do
          Ree::BenchmarkTracer.trace('child/fn1') { nil }
          Ree::BenchmarkTracer.trace('child/fn2') do
            Ree::BenchmarkTracer.trace('grandchild/fn') { nil }
          end
        end
      end

      lines = output.split("\n")
      expect(lines.size).to eq(4)
      expect(lines[0]).to match(/^parent\/fn \(\d+\.\d+ms\)$/)
      expect(lines[1]).to match(/^  child\/fn1 \(\d+\.\d+ms\)$/)
      expect(lines[2]).to match(/^  child\/fn2 \(\d+\.\d+ms\)$/)
      expect(lines[3]).to match(/^    grandchild\/fn \(\d+\.\d+ms\)$/)
    end

    it 'cleans up thread-local stack after root call completes' do
      with_captured_stdout do
        Ree::BenchmarkTracer.trace('test/fn') { nil }
      end

      expect(Thread.current[:ree_benchmark_tracer]).to be_nil
    end

    it 'still prints tree when block raises an exception' do
      output = with_captured_stdout do
        begin
          Ree::BenchmarkTracer.trace('test/fn') { raise 'boom' }
        rescue RuntimeError
        end
      end

      expect(output).to match(/^test\/fn \(\d+\.\d+ms\)\n$/)
    end
  end

  describe '.collect' do
    after do
      Thread.current[:ree_benchmark_tracer] = nil
    end

    it 'is a no-op when no trace is active' do
      output = with_captured_stdout do
        result = Ree::BenchmarkTracer.collect('some/fn') { 42 }
        expect(result).to eq(42)
      end

      expect(output).to eq('')
    end

    it 'participates in an active trace' do
      output = with_captured_stdout do
        Ree::BenchmarkTracer.trace('parent/fn') do
          Ree::BenchmarkTracer.collect('child/fn') { nil }
        end
      end

      lines = output.split("\n")
      expect(lines.size).to eq(2)
      expect(lines[0]).to match(/^parent\/fn \(\d+\.\d+ms\)$/)
      expect(lines[1]).to match(/^  child\/fn \(\d+\.\d+ms\)$/)
    end
  end

  describe '.format_tree' do
    it 'shows only root node when deep: false' do
      output = with_captured_stdout do
        Ree::BenchmarkTracer.trace('parent/fn', deep: false) do
          Ree::BenchmarkTracer.trace('child/fn') { nil }
        end
      end

      lines = output.split("\n")
      expect(lines.size).to eq(1)
      expect(lines[0]).to match(/^parent\/fn \(\d+\.\d+ms\)$/)
    end

    it 'shows full tree when deep: true' do
      output = with_captured_stdout do
        Ree::BenchmarkTracer.trace('parent/fn', deep: true) do
          Ree::BenchmarkTracer.trace('child/fn') { nil }
        end
      end

      lines = output.split("\n")
      expect(lines.size).to eq(2)
      expect(lines[0]).to match(/^parent\/fn \(\d+\.\d+ms\)$/)
      expect(lines[1]).to match(/^  child\/fn \(\d+\.\d+ms\)$/)
    end
  end

  describe 'output_proc' do
    it 'routes output through custom lambda' do
      collected = nil

      silent_output = with_captured_stdout do
        Ree::BenchmarkTracer.trace('test/fn', output_proc: -> (res) { collected = res }) { 42 }
      end

      expect(silent_output).to eq('')
      expect(collected).to match(/^test\/fn \(\d+\.\d+ms\)$/)
    end
  end

  describe 'integration with plugin system' do
    Ree.enable_benchmark_mode
    Ree.enable_irb_mode

    module BenchmarkPluginTestPkg
      include Ree::PackageDSL
      package

      class CollectorFn
        include Ree::FnDSL

        fn :collector_fn

        contract Integer => Integer
        def call(x)
          x + 1
        end
      end

      class EntryPointFn
        include Ree::FnDSL

        fn :entry_point_fn do
          link :collector_fn
          benchmark
        end

        contract Integer => Integer
        def call(x)
          collector_fn(x)
        end
      end

      class ShallowEntryFn
        include Ree::FnDSL

        fn :shallow_entry_fn do
          link :collector_fn
          benchmark deep: false
        end

        contract Integer => Integer
        def call(x)
          collector_fn(x)
        end
      end

      class OnceFn
        include Ree::FnDSL

        fn :once_fn do
          benchmark once: true
        end

        contract Integer => Integer
        def call(x)
          x * 2
        end
      end

      class CustomOutputFn
        include Ree::FnDSL

        fn :custom_output_fn do
          benchmark output: -> (res) { $custom_benchmark_output = res }
        end

        contract Integer => Integer
        def call(x)
          x + 10
        end
      end
    end

    Ree.disable_irb_mode

    it 'entry point fn produces benchmark output' do
      output = with_captured_stdout do
        BenchmarkPluginTestPkg::EntryPointFn.new.call(1)
      end

      lines = output.split("\n")
      expect(lines.size).to eq(2)
      expect(lines[0]).to match(/^benchmark_plugin_test_pkg\/entry_point_fn \(\d+\.\d+ms\)$/)
      expect(lines[1]).to match(/^  benchmark_plugin_test_pkg\/collector_fn \(\d+\.\d+ms\)$/)
    end

    it 'collector fn alone produces no output' do
      output = with_captured_stdout do
        BenchmarkPluginTestPkg::CollectorFn.new.call(1)
      end

      expect(output).to eq('')
    end

    it 'deep: false shows only root node' do
      output = with_captured_stdout do
        BenchmarkPluginTestPkg::ShallowEntryFn.new.call(1)
      end

      lines = output.split("\n")
      expect(lines.size).to eq(1)
      expect(lines[0]).to match(/^benchmark_plugin_test_pkg\/shallow_entry_fn \(\d+\.\d+ms\)$/)
    end

    it 'once: true outputs only on first call' do
      first_output = with_captured_stdout do
        BenchmarkPluginTestPkg::OnceFn.new.call(5)
      end

      expect(first_output).to match(/^benchmark_plugin_test_pkg\/once_fn \(\d+\.\d+ms\)\n$/)

      second_output = with_captured_stdout do
        BenchmarkPluginTestPkg::OnceFn.new.call(5)
      end

      expect(second_output).to eq('')
    end

    it 'custom output: routes output through lambda' do
      $custom_benchmark_output = nil

      silent = with_captured_stdout do
        BenchmarkPluginTestPkg::CustomOutputFn.new.call(5)
      end

      expect(silent).to eq('')
      expect($custom_benchmark_output).to match(/^benchmark_plugin_test_pkg\/custom_output_fn \(\d+\.\d+ms\)$/)
    end

    it 'contract still validates args on benchmarked fn' do
      expect {
        with_captured_stdout do
          BenchmarkPluginTestPkg::EntryPointFn.new.call("not_an_integer")
        end
      }.to raise_error(Ree::Contracts::ContractError)
    end

    it 'contract still validates args on collector fn' do
      expect {
        BenchmarkPluginTestPkg::CollectorFn.new.call("not_an_integer")
      }.to raise_error(Ree::Contracts::ContractError)
    end

    it 'returns correct result through benchmark + contract wrappers' do
      result = nil
      with_captured_stdout do
        result = BenchmarkPluginTestPkg::EntryPointFn.new.call(5)
      end

      expect(result).to eq(6)
    end
  end

  describe 'no output when benchmark mode is off' do
    Ree.disable_benchmark_mode
    Ree.enable_irb_mode

    module NoBenchmarkPkg
      include Ree::PackageDSL
      package

      class NoTraceFn
        include Ree::FnDSL

        fn :no_trace_fn

        def call
          :no_trace
        end
      end
    end

    Ree.disable_irb_mode

    it 'produces no benchmark output for fns compiled without benchmark mode' do
      output = with_captured_stdout do
        NoBenchmarkPkg::NoTraceFn.new.call
      end

      expect(output).to eq('')
    end
  end

  describe 'benchmark mode toggle' do
    it 'can be enabled and disabled' do
      Ree.enable_benchmark_mode
      expect(Ree.benchmark_mode?).to eq(true)

      Ree.disable_benchmark_mode
      expect(Ree.benchmark_mode?).to eq(false)
    end
  end
end
