module BackgroundWorker
  include Ree::PackageDSL
  
  package do
    depends_on :domain_package
  end
end
