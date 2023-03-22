require "roda"

module ReeRoda
  include Ree::PackageDSL

  package do
    depends_on :ree_routes
    depends_on :ree_logger
    depends_on :ree_json
    depends_on :ree_hash
    depends_on :ree_object
    depends_on :ree_swagger
    depends_on :ree_errors
  end
end

package_require "ree_roda/plugins/ree_logger"
package_require "ree_roda/plugins/ree_routes"
package_require "ree_roda/app"
