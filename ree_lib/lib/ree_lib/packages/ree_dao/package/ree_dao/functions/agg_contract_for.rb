# frozen_string_literal: true

class ReeDao::AggContractFor
  include Ree::FnDSL

  fn :agg_contract_for do
    target :class
    with_caller
  end

  contract(Any => nil)
  def call(klass)
    get_caller.contract(
      Or[Sequel::Dataset, ArrayOf[Integer], Integer, ArrayOf[klass]],
      Ksplat[
        only?: ArrayOf[Symbol],
        except?: ArrayOf[Symbol],
        RestKeys => Any
      ] => ArrayOf[klass]
    )

    nil
  end
end