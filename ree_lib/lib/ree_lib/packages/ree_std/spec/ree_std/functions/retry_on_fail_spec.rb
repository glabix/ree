# frozen_string_literal: true

RSpec.describe :retry_on_fail do
  link :retry_on_fail, from: :ree_std

  SampleException     = Class.new(StandardError)
  YetAnotherException = Class.new(StandardError)

  class TestRetryProcedure
    def initialize(failed_count: 0, raise_error:)
      @failed_count = failed_count
      @raise_error = raise_error
      @current_attempt = 0
    end

    def call
      unless succeed?
        @current_attempt += 1
        raise @raise_error
      end
    end

    def succeed?
      @current_attempt > @failed_count
    end
  end

  describe "handles specific exception" do
    let(:procedure) { TestRetryProcedure.new(failed_count: 1, raise_error: SampleException.new("sample exception message")) }

    before(:each) do
      @message = nil

      retry_on_fail(
        max: 2,
        exceptions: [SampleException],
        retry_block: ->(attempt, e) { @message = "Attempt ##{attempt}: '#{e.message}'"  },
      ) { procedure.call }
    end

    it "should reach succeed case if failed count is less than max retries" do
      expect(procedure.succeed?).to be true
    end

    it "should execute :retry_block" do
      expect(@message).to eq("Attempt #1: 'sample exception message'")
    end
  end

  describe "when max attempts was reached" do
    let(:procedure) { TestRetryProcedure.new(failed_count: 3, raise_error: SampleException) }

    it "raises error" do
      expect {
        retry_on_fail(
          max: 2,
          retry_if: ->(e) { e.is_a?(SampleException) && e.message == 'sample exception message' }
        ) { procedure.call }
      }.to raise_error(SampleException)
    end
  end

  describe "when handle another exception" do
    let(:procedure) { TestRetryProcedure.new(failed_count: 1, raise_error: YetAnotherException) }

    it "raises error" do
      expect {
        retry_on_fail(
          max: 2,
          exceptions: [SampleException],
        ) { procedure.call }
      }.to raise_error(YetAnotherException)
    end
  end

  describe ":retry_if parameter" do
    let(:procedure) { TestRetryProcedure.new(failed_count: 1, raise_error: SampleException) }

    it "checks positive case" do
      expect {
        retry_on_fail(
          max: 2,
          retry_if: ->(e) { e.class == SampleException }
        ) { procedure.call }
      }.not_to raise_error
    end

    it "checks negative case" do
      expect {
        retry_on_fail(
          max: 2,
          retry_if: ->(e) { e.class == YetAnotherException }
        ) { procedure.call }
      }.to raise_error(SampleException)
    end
  end
end