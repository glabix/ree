class SamplePackage::User
  include ReeDto::DSL
  include Ree::LinkDSL

  build_dto do
    column :email, String
  end
end