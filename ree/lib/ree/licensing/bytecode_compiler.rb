# frozen_string_literal: true

module Ree
  module Licensing
    class BytecodeCompiler
      def self.compile_file(path)
        iseq = RubyVM::InstructionSequence.compile_file(path)
        iseq.to_binary
      end

      def self.compile_string(source, path = "(eval)")
        iseq = RubyVM::InstructionSequence.compile(source, path)
        iseq.to_binary
      end

      def self.load_from_binary(binary)
        RubyVM::InstructionSequence.load_from_binary(binary)
      end
    end
  end
end
