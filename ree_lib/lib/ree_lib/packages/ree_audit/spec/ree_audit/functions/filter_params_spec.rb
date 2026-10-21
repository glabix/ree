# frozen_string_literal: true

package_require('ree_audit/functions/filter_params')

RSpec.describe :filter_params do
  link :filter_params, from: :ree_audit

  it "leaves a plain payload untouched" do
    expect(filter_params({page: 1, per_page: 25})).to eq({page: 1, per_page: 25})
  end

  it "filters a secret sitting at the top level" do
    expect(filter_params({password: "hunter2", page: 1})).to eq(
      {password: 'FILTERED', page: 1}
    )
  end

  it "filters a secret nested three levels deep" do
    result = filter_params({user: {profile: {user_password: "hunter2", name: "Ann"}}})

    expect(result).to eq(
      {user: {profile: {user_password: 'FILTERED', name: "Ann"}}}
    )
  end

  it "filters inside an array of hashes" do
    result = filter_params({items: [{auth_token: "t"}, {name: "ok"}]})

    expect(result).to eq({items: [{auth_token: 'FILTERED'}, {name: "ok"}]})
  end

  it "matches filter words on string keys as well" do
    expect(filter_params({"Authorization" => "Bearer x"})).to eq(
      {"Authorization" => 'FILTERED'}
    )
  end

  it "cuts everything deeper than the configured depth" do
    result = filter_params({a: {b: {c: {d: {e: 1}}}}})

    expect(result).to eq({a: {b: {c: {d: '[TRUNCATED_DEPTH]'}}}})
  end

  it "replaces an oversized payload with its size" do
    result = filter_params({blob: "x" * 5000})

    expect(result[:truncated]).to eq(true)
    expect(result[:size]).to be > 4096
    expect(result[:blob]).to be_nil
  end

  it "keeps a payload that fits the size limit" do
    result = filter_params({blob: "x" * 100})

    expect(result[:truncated]).to be_nil
    expect(result[:blob]).to eq("x" * 100)
  end
end
