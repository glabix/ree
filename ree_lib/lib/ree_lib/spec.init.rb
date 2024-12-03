require 'bootsnap'

Bootsnap.setup(
  cache_dir: '/tmp/bootsnap_cache',
  development_mode: true,
  load_path_cache: true,
  compile_cache_iseq: true,
  compile_cache_yaml: true
)

require 'rspec'
require 'ree'

ENV["RUBY_ENV"] = "test"

Ree.init(__dir__)
