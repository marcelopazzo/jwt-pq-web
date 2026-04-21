# Regenerate test fixtures (signed tokens + matching JWKs) for every
# supported ML-DSA parameter set. Run once and commit the output:
#
#   bundle exec ruby script/generate_fixtures.rb
#
# The resulting JWK files include the `priv` field so tests can re-sign
# with the same key if needed. They are public demo keys and must not be
# reused anywhere production-facing.

require "bundler/setup"
require "fileutils"
require "jwt"
require "jwt/pq"
require "json"

ALGORITHMS = %i[ml_dsa_44 ml_dsa_65 ml_dsa_87].freeze
FIXTURE_DIR = File.expand_path("../test/fixtures", __dir__)

FileUtils.mkdir_p(FIXTURE_DIR)

ALGORITHMS.each do |alg_sym|
  key = JWT::PQ::Key.generate(alg_sym)
  alg = alg_sym.to_s.upcase.tr("_", "-")
  token = JWT.encode({ sub: "fixture", iat: Time.now.to_i }, key, alg)

  File.write(
    File.join(FIXTURE_DIR, "#{alg_sym}.jwk.json"),
    JSON.pretty_generate(JWT::PQ::JWK.new(key).export(include_private: true))
  )
  File.write(File.join(FIXTURE_DIR, "#{alg_sym}.token"), token)

  puts "Wrote fixtures for #{alg}"
ensure
  key&.destroy!
end
