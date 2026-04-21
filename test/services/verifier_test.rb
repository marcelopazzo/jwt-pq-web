require "test_helper"

class VerifierTest < ActiveSupport::TestCase
  ALLOWED = %w[ML-DSA-44 ML-DSA-65 ML-DSA-87].freeze

  test "verifies a good token against a matching JWK" do
    fixture = jwt_pq_fixture(:ml_dsa_65)
    result = Verifier.new(
      token: fixture[:token],
      pubkey: JSON.generate(fixture[:jwk]),
      allowed_algs: ALLOWED
    ).call

    assert result.valid
    assert_equal :ok, result.http_status
    assert_equal "ML-DSA-65", result.body[:algorithm]
  end

  test "returns signature_mismatch for tampered token" do
    fixture = jwt_pq_fixture(:ml_dsa_65)
    parts = fixture[:token].split(".")
    tampered = [ parts[0], parts[1], Base64.urlsafe_encode64("nope", padding: false) ].join(".")

    result = Verifier.new(
      token: tampered,
      pubkey: JSON.generate(fixture[:jwk]),
      allowed_algs: ALLOWED
    ).call

    assert_equal false, result.valid
    assert_equal :ok, result.http_status
    assert_equal "signature_mismatch", result.body[:error]
  end

  test "returns invalid_jwk_json when JWK is not JSON" do
    fixture = jwt_pq_fixture(:ml_dsa_65)
    result = Verifier.new(
      token: fixture[:token],
      pubkey: "not a json",
      allowed_algs: ALLOWED
    ).call

    assert_equal false, result.valid
    assert_equal :unprocessable_entity, result.http_status
    assert_equal "invalid_jwk_json", result.body[:error]
  end

  test "returns disallowed_algorithm when alg is not in allowlist" do
    hs_token = JWT.encode({ sub: "x" }, "secret", "HS256")
    fixture = jwt_pq_fixture(:ml_dsa_65)

    result = Verifier.new(
      token: hs_token,
      pubkey: JSON.generate(fixture[:jwk]),
      allowed_algs: ALLOWED
    ).call

    assert_equal false, result.valid
    assert_equal :unprocessable_entity, result.http_status
    assert_equal "disallowed_algorithm", result.body[:error]
  end
end
