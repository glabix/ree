# frozen_string_literal: true

class Ree::BenchmarkTracer
  Node = Struct.new(:name, :start_time, :duration, :children)

  THREAD_KEY = :ree_benchmark_tracer

  class << self
    # Entry point trace — starts collection, outputs when root completes
    def trace(name, output_proc: nil, deep: true)
      stack = Thread.current[THREAD_KEY] ||= []
      node = Node.new(name, Process.clock_gettime(Process::CLOCK_MONOTONIC), nil, [])
      stack.last.children.push(node) if stack.last
      is_root = stack.empty? || stack.last.nil?
      stack.push(node)

      begin
        result = yield
      ensure
        node.duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - node.start_time
        stack.pop

        if stack.empty?
          Thread.current[THREAD_KEY] = nil

          if output_proc
            output_proc.call(format_tree(node, deep: deep))
          else
            $stdout.puts(format_tree(node, deep: deep))
          end
        end
      end

      result
    end

    def active?
      stack = Thread.current[THREAD_KEY]
      stack && !stack.empty?
    end

    # Collector trace — only participates if a trace is already active
    def collect(name)
      stack = Thread.current[THREAD_KEY]
      return yield unless stack && !stack.empty?

      node = Node.new(name, Process.clock_gettime(Process::CLOCK_MONOTONIC), nil, [])
      stack.last.children.push(node)
      stack.push(node)

      begin
        result = yield
      ensure
        node.duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - node.start_time
        stack.pop
      end

      result
    end

    # Format tree as a string
    # deep: false → only root node, deep: true → full tree
    def format_tree(node, deep: true)
      lines = []
      build_tree_lines(node, 0, lines, deep: deep)
      lines.join("\n")
    end

    private

    def build_tree_lines(node, depth, lines, deep: true)
      indent = "  " * depth
      duration_ms = (node.duration * 1000).round(2)
      lines << "#{indent}#{node.name} (#{duration_ms}ms)"

      if deep
        node.children.each { |child| build_tree_lines(child, depth + 1, lines) }
      end
    end
  end
end
