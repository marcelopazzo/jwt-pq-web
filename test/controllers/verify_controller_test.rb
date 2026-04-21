require "test_helper"

class VerifyControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
  end

  %i[ml_dsa_44 ml_dsa_65 ml_dsa_87].each do |alg_sym|
    test "happy path for #{alg_sym}" do
      fixture = jwt_pq_fixture(alg_sym)
      post verify_url,
        params: { token: fixture[:token], pubkey: JSON.generate(jwt_pq_public_jwk(alg_sym)) },
        as: :json

      assert_response :success
      body = JSON.parse(response.body)
      assert_equal true, body["valid"]
      assert_equal fixture[:algorithm], body["algorithm"]
    end
  end

  test "bad signature returns 200 with valid false" do
    fixture = jwt_pq_fixture(:ml_dsa_65)
    parts = fixture[:token].split(".")
    tampered = [ parts[0], parts[1], Base64.urlsafe_encode64("bogus" * 100, padding: false) ].join(".")

    post verify_url,
      params: { token: tampered, pubkey: JSON.generate(jwt_pq_public_jwk(:ml_dsa_65)) },
      as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal false, body["valid"]
    assert_equal "signature_mismatch", body["error"]
  end

  test "malformed JWK returns 422" do
    fixture = jwt_pq_fixture(:ml_dsa_65)
    post verify_url,
      params: { token: fixture[:token], pubkey: "not-json" },
      as: :json

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_equal "invalid_jwk_json", body["error"]
  end

  test "disallowed algorithm returns 422" do
    # Sign with HS256 so the header alg is outside the allowlist.
    hs_token = JWT.encode({ sub: "x" }, "secret", "HS256")

    post verify_url,
      params: { token: hs_token, pubkey: JSON.generate(jwt_pq_public_jwk(:ml_dsa_65)) },
      as: :json

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_equal "disallowed_algorithm", body["error"]
  end

  test "oversized token returns 413" do
    post verify_url,
      params: { token: "A" * 20_000, pubkey: JSON.generate(jwt_pq_public_jwk(:ml_dsa_65)) },
      as: :json

    assert_response :content_too_large
    body = JSON.parse(response.body)
    assert_equal "payload_too_large", body["error"]
    assert_equal "token", body["detail"]
  end

  test "oversized pubkey returns 413" do
    fixture = jwt_pq_fixture(:ml_dsa_65)
    post verify_url,
      params: { token: fixture[:token], pubkey: "A" * 10_000 },
      as: :json

    assert_response :content_too_large
    body = JSON.parse(response.body)
    assert_equal "payload_too_large", body["error"]
    assert_equal "pubkey", body["detail"]
  end

  test "missing parameter returns 400" do
    post verify_url, params: {}, as: :json

    assert_response :bad_request
    body = JSON.parse(response.body)
    assert_equal "missing_parameter", body["error"]
  end

  test "rate limit returns 429 after 10 requests" do
    fixture = jwt_pq_fixture(:ml_dsa_65)
    params = { token: fixture[:token], pubkey: JSON.generate(jwt_pq_public_jwk(:ml_dsa_65)) }

    11.times do |i|
      post verify_url, params: params, as: :json
      if i < 10
        assert_response :success, "request #{i + 1} should succeed"
      else
        assert_response :too_many_requests, "request #{i + 1} should be rate-limited"
      end
    end
  end
end
