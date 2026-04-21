require "test_helper"

class JwksControllerTest < ActionDispatch::IntegrationTest
  test "returns a well-formed JWK Set" do
    get jwks_url
    assert_response :success

    body = JSON.parse(response.body)
    assert body.key?("keys")
    assert_instance_of Array, body["keys"]
    assert body["keys"].any?
  end

  test "each key has kty and alg and no priv" do
    get jwks_url
    body = JSON.parse(response.body)

    body["keys"].each do |key|
      assert_equal "AKP", key["kty"]
      assert key["alg"].present?, "expected alg"
      assert key["kid"].present?, "expected kid"
      assert key["pub"].present?, "expected pub"
      refute key.key?("priv"), "JWKS must never expose priv"
    end
  end

  test "sets public cache headers and CORS" do
    get jwks_url

    assert_match(/public/, response.headers["Cache-Control"].to_s)
    assert_match(/max-age=3600/, response.headers["Cache-Control"].to_s)
    assert_equal "*", response.headers["Access-Control-Allow-Origin"]
  end
end
