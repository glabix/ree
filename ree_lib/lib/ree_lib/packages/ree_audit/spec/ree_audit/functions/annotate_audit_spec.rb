# frozen_string_literal: true

package_require('ree_audit/functions/annotate_audit')
package_require('ree_audit/event')

RSpec.describe :annotate_audit do
  link :annotate_audit, from: :ree_audit

  before { ReeAudit::Context.clear }
  after { ReeAudit::Context.clear }

  it "returns nil outside an audited call" do
    expect(annotate_audit(permission: :access_uploads)).to be_nil
  end

  it "merges into the current event" do
    event = ReeAudit::Event.build(action_name: :some_query)
    ReeAudit::Context.push(event)

    annotate_audit(permission: :access_uploads)
    annotate_audit(subject: {type: :upload, id: "abc"})

    expect(event.annotations).to eq({
      permission: :access_uploads,
      subject: {type: :upload, id: "abc"}
    })
  end
end
