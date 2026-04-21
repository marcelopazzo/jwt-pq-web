# Decodes a JWT against a JWK the caller supplied, restricted to an explicit
# algorithm allowlist. Signature mismatches return a 200 with `valid: false`
# because the service did its job — only genuine bad-request conditions
# (malformed JWK, disallowed algorithm, unparseable token) return 4xx.
class Verifier
  Result = Struct.new(:valid, :http_status, :body, keyword_init: true) do
    def as_json(*) = body
  end

  def initialize(token:, pubkey:, allowed_algs:)
    @token = token
    @pubkey_raw = pubkey
    @allowed_algs = allowed_algs
  end

  def call
    jwk_hash = JSON.parse(@pubkey_raw, symbolize_names: true)
    key = JWT::PQ::JWK.import(jwk_hash)

    decoded_payload, header = JWT.decode(
      @token, key, true,
      algorithms: @allowed_algs,
      verify_expiration: false
    )

    Result.new(
      valid: true,
      http_status: :ok,
      body: {
        valid: true,
        header: header,
        payload: decoded_payload,
        algorithm: header["alg"]
      }
    )
  rescue JSON::ParserError
    fail_with("invalid_jwk_json", :unprocessable_entity)
  rescue JWT::PQ::KeyError => e
    fail_with("invalid_jwk", :unprocessable_entity, e.message)
  rescue JWT::IncorrectAlgorithm
    fail_with("disallowed_algorithm", :unprocessable_entity)
  rescue JWT::VerificationError
    fail_with("signature_mismatch", :ok)
  rescue JWT::DecodeError => e
    fail_with("malformed_token", :unprocessable_entity, e.class.name)
  end

  private

  def fail_with(code, status, detail = nil)
    Result.new(
      valid: false,
      http_status: status,
      body: { valid: false, error: code, detail: detail }.compact
    )
  end
end
