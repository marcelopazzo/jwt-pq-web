# Generates an ephemeral ML-DSA keypair, signs a non-expiring demo payload,
# and returns the matching public JWK so adopters can paste both into the
# debugger and see a successful verification.
#
# Hybrid samples are intentionally deferred until jwt-pq ships a canonical
# hybrid JWK export format.
class SampleTokenFactory
  HYBRID_PREFIX = "hybrid_"

  def initialize(alg_id)
    @alg_id = alg_id.to_s
  end

  def call
    if @alg_id.start_with?(HYBRID_PREFIX)
      build_hybrid
    else
      build_ml_dsa
    end
  end

  private

  def build_ml_dsa
    sym = @alg_id.to_sym
    key = JWT::PQ::Key.generate(sym)
    alg = sym.to_s.upcase.tr("_", "-")
    token = JWT.encode(sample_payload, key, alg)
    jwk = JWT::PQ::JWK.new(key).export
    { token: token, jwk: jwk, algorithm: alg }
  ensure
    key&.destroy!
  end

  def build_hybrid
    raise NotImplementedError, "Hybrid JWK export pending gem support"
  end

  def sample_payload
    {
      iss: "https://jwt-pq.marcelopazzo.com",
      sub: "sample-user",
      iat: Time.now.to_i,
      note: "This is a public demo token — not secret, not authoritative."
    }
  end
end
