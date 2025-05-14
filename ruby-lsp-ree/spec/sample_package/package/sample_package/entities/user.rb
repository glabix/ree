class SamplePackage::User
  include ReeDto::DSL
  include Ree::LinkDSL

  build_dto do
    db_field :email, String
  end
end