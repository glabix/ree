# frozen_string_literal: true

package_require('ree_audit/event')

RSpec.describe ReeAudit::Context do
  let(:event) { ReeAudit::Event.build(action_name: :some_query) }

  before { ReeAudit::Context.clear }
  after { ReeAudit::Context.clear }

  it "is empty by default" do
    expect(ReeAudit::Context.current).to be_nil
    expect(ReeAudit::Context).to be_empty
  end

  it "pushes and pops" do
    ReeAudit::Context.push(event)
    expect(ReeAudit::Context.current).to eq(event)

    expect(ReeAudit::Context.pop).to eq(event)
    expect(ReeAudit::Context.current).to be_nil
  end

  # A leftover event would be picked up by the next request served by the same
  # fiber — one client's annotations landing on another client's trail.
  it "is unwound even when the wrapped call raises" do
    expect {
      begin
        ReeAudit::Context.push(event)
        raise ArgumentError.new("boom")
      ensure
        ReeAudit::Context.pop
      end
    }.to raise_error(ArgumentError)

    expect(ReeAudit::Context.current).to be_nil
  end

  it "keeps stacks of different threads apart" do
    ReeAudit::Context.push(event)

    other = Thread.new { ReeAudit::Context.current }.value

    expect(other).to be_nil
    expect(ReeAudit::Context.current).to eq(event)
  end
end
