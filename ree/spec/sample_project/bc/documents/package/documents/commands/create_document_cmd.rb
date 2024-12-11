class Documents::CreateDocumentCmd
  include Ree::FnDSL

  fn :create_document_cmd do
  end

  doc("Create document")
  contract(Integer => Integer)
  def call(user_id)
    return 1
  end
end


