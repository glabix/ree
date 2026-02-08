# frozen_string_literal: true

class Ree::BenchmarkTracer
  Node = Struct.new(:name, :start_time, :duration, :children)

  THREAD_KEY = :ree_benchmark_tracer

  class << self
    def trace(name)
      stack = Thread.current[THREAD_KEY] ||= []
      node = Node.new(name, Process.clock_gettime(Process::CLOCK_MONOTONIC), nil, [])
      stack.last.children.push(node) if stack.last
      stack.push(node)

      begin
        result = yield
      ensure
        node.duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - node.start_time
        stack.pop

        if stack.empty?
          Thread.current[THREAD_KEY] = nil
          print_tree(node)
        end
      end

      result
    end

    private

    def print_tree(node, depth = 0)
      indent = "  " * depth
      duration_ms = (node.duration * 1000).round(2)
      $stdout.puts "#{indent}#{node.name} (#{duration_ms}ms)"
      node.children.each { |child| print_tree(child, depth + 1) }
    end
  end
end
