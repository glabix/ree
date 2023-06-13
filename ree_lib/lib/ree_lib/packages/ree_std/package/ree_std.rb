module ReeStd
  include Ree::PackageDSL

  package do
    # Example of usage:
    # tags ['wip']
    # depends_on :package_name
    # env_var 'ENV_VAR_NAME'
    # preload(
    #   production: [
    #     :bean_or_fn
    #   ]  
    # )
  end
end
