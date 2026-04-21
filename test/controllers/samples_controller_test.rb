require "test_helper"

class SamplesControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
  end

  test "ML-DSA-65 sample verifies with its own JWK" do
    get sample_url(id: "ml_dsa_65")
    assert_response :success

    body = JSON.parse(response.body, symbolize_names: true)
    assert_equal "ML-DSA-65", body[:algorithm]
    assert body[:token].present?
    assert_equal "AKP", body[:jwk][:kty]

    key = JWT::PQ::JWK.import(body[:jwk])
    decoded, header = JWT.decode(body[:token], key, true, algorithms: [ "ML-DSA-65" ])
    assert_equal "ML-DSA-65", header["alg"]
    assert_equal "sample-user", decoded["sub"]
  end

  test "unknown id returns 404" do
    get "/samples/bogus"
    assert_response :not_found
  end

  test "hybrid id returns 501 while unsupported" do
    get sample_url(id: "hybrid_ml_dsa_65")
    assert_response :not_implemented
  end
end
