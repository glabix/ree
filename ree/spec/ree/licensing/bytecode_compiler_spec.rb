# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe Ree::Licensing::BytecodeCompiler do
  describe '.compile_file' do
    it 'compiles a Ruby file to YARV bytecode' do
      tmp_dir = Dir.mktmpdir
      file_path = File.join(tmp_dir, 'test.rb')
      File.write(file_path, "1 + 2")

      bytecode = described_class.compile_file(file_path)

      expect(bytecode).to be_a(String)
      expect(bytecode.encoding).to eq(Encoding::ASCII_8BIT)
      expect(bytecode.size).to be > 0
    ensure
      FileUtils.rm_rf(tmp_dir)
    end
  end

  describe '.compile_string' do
    it 'compiles a Ruby string to YARV bytecode' do
      bytecode = described_class.compile_string("2 + 3")

      expect(bytecode).to be_a(String)
      expect(bytecode.size).to be > 0
    end
  end

  describe '.load_from_binary' do
    it 'loads bytecode and evaluates it' do
      bytecode = described_class.compile_string("2 + 3")
      iseq = described_class.load_from_binary(bytecode)

      expect(iseq).to be_a(RubyVM::InstructionSequence)
      expect(iseq.eval).to eq(5)
    end
  end

  describe 'compile and load round-trip' do
    it 'preserves code semantics through bytecode' do
      tmp_dir = Dir.mktmpdir
      file_path = File.join(tmp_dir, 'round_trip.rb')
      File.write(file_path, <<~RUBY)
        module RoundTripTest
          def self.compute
            42
          end
        end
      RUBY

      bytecode = described_class.compile_file(file_path)
      iseq = described_class.load_from_binary(bytecode)
      iseq.eval

      expect(RoundTripTest.compute).to eq(42)
    ensure
      Object.send(:remove_const, :RoundTripTest) if defined?(RoundTripTest)
      FileUtils.rm_rf(tmp_dir)
    end
  end
end
