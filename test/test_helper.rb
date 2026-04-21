ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    def jwt_pq_fixture(alg_sym)
      jwk_path = Rails.root.join("test/fixtures", "#{alg_sym}.jwk.json")
      token_path = Rails.root.join("test/fixtures", "#{alg_sym}.token")
      jwk = ::JSON.parse(File.read(jwk_path), symbolize_names: true)
      token = File.read(token_path).strip
      { jwk: jwk, token: token, algorithm: alg_sym.to_s.upcase.tr("_", "-") }
    end

    def jwt_pq_public_jwk(alg_sym)
      fixture = jwt_pq_fixture(alg_sym)
      fixture[:jwk].except(:priv)
    end
  end
end
