class Documents::CreateDocumentCmd
  include Ree::FnDSL

  fn :create_document_cmd do
    link :do_nothing, from: :string_utils
  end

  doc("Create document")
  contract(Integer => Integer)
  def call(user_id)
    do_nothing(user_id.to_s)
    return 1
  end
end


