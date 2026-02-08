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

  describe 'integration with ObjectCompiler' do
    Ree.enable_benchmark_mode
    Ree.enable_irb_mode

    module BenchmarkTestPkg
      include Ree::PackageDSL
      package

      class InnerFn
        include Ree::FnDSL

        fn :inner_fn

        def call
          :inner_result
        end
      end

      class OuterFn
        include Ree::FnDSL

        fn :outer_fn do
          link :inner_fn
        end

        def call
          inner_fn
        end
      end

      class WithCallerFn
        include Ree::FnDSL

        fn :with_caller_fn do
          with_caller
          link :inner_fn
        end

        def call
          inner_fn
        end
      end
    end

    Ree.disable_irb_mode

    it 'traces fn call and prints to stdout' do
      output = with_captured_stdout do
        BenchmarkTestPkg::InnerFn.new.call
      end

      expect(output).to match(/^benchmark_test_pkg\/inner_fn \(\d+\.\d+ms\)\n$/)
    end

    it 'traces nested fn calls as indented tree' do
      output = with_captured_stdout do
        BenchmarkTestPkg::OuterFn.new.call
      end

      lines = output.split("\n")
      expect(lines.size).to eq(2)
      expect(lines[0]).to match(/^benchmark_test_pkg\/outer_fn \(\d+\.\d+ms\)$/)
      expect(lines[1]).to match(/^  benchmark_test_pkg\/inner_fn \(\d+\.\d+ms\)$/)
    end

    it 'traces with_caller fn calls' do
      output = with_captured_stdout do
        BenchmarkTestPkg::WithCallerFn.new.set_caller(self).call
      end

      lines = output.split("\n")
      expect(lines.size).to eq(2)
      expect(lines[0]).to match(/^benchmark_test_pkg\/with_caller_fn \(\d+\.\d+ms\)$/)
      expect(lines[1]).to match(/^  benchmark_test_pkg\/inner_fn \(\d+\.\d+ms\)$/)
    end

    it 'does not double-prepend on recompilation' do
      klass = BenchmarkTestPkg::InnerFn
      ancestors_before = klass.ancestors.dup

      obj = Ree.container.packages_facade.get_package(:benchmark_test_pkg).get_object(:inner_fn)
      obj.set_as_compiled(false)
      Ree::ObjectCompiler.new(Ree.container.packages_facade).call(:benchmark_test_pkg, :inner_fn)

      expect(klass.ancestors).to eq(ancestors_before)
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
