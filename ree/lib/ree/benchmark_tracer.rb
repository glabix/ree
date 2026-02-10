# frozen_string_literal: true

class Ree::BenchmarkTracer
  Node = Struct.new(:name, :start_time, :duration, :children)

  THREAD_KEY = :ree_benchmark_tracer

  class << self
    # Entry point trace — starts collection, outputs when root completes
    def trace(name, output_proc: nil, deep: true, hide_ree_lib: true)
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
            output_proc.call(format_tree(node, deep: deep, hide_ree_lib: hide_ree_lib))
          else
            $stdout.puts(format_tree(node, deep: deep, hide_ree_lib: hide_ree_lib))
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
    def format_tree(node, deep: true, hide_ree_lib: true)
      lines = []
      build_tree_lines(node, 0, lines, deep: deep, hide_ree_lib: hide_ree_lib)
      lines.join("\n")
    end

    private

    def build_tree_lines(node, depth, lines, deep: true, hide_ree_lib: true)
      # Check if this node should be filtered (ree_ package)
      should_filter = hide_ree_lib && node.name.start_with?('ree_')

      if should_filter
        # Skip this node but process its children at the current depth (promote them)
        if deep
          node.children.each { |child| build_tree_lines(child, depth, lines, deep: deep, hide_ree_lib: hide_ree_lib) }
        end
      else
        # Normal path: show this node
        indent = "  " * depth
        duration_ms = (node.duration * 1000).round(2)
        lines << "#{indent}#{node.name} (#{duration_ms}ms)"

        if deep
          node.children.each { |child| build_tree_lines(child, depth + 1, lines, deep: deep, hide_ree_lib: hide_ree_lib) }
        end
      end
    end
  end
end
