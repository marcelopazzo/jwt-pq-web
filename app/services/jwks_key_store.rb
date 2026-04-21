# Loads or generates a long-lived ML-DSA-65 JWKS signing key on a persistent
# volume and returns a public JWK set. The private key stays on disk with
# 0600 permissions and is never served over HTTP.
class JwksKeyStore
  class << self
    # Returns the current JWK Set with public keys only.
    def current_jwks
      { keys: [ public_jwk ] }
    end

    # Returns the public JWK (no `priv`) used by the site.
    def public_jwk
      ensure_key!
      JSON.parse(File.read(public_path), symbolize_names: true)
    end

    # Deletes the persisted key material so the next call regenerates.
    # Used by `lib/tasks/jwks.rake`.
    def rotate!
      File.delete(public_path) if File.exist?(public_path)
      File.delete(private_path) if File.exist?(private_path)
      ensure_key!
    end

    private

    def ensure_key!
      return if File.exist?(public_path) && File.exist?(private_path)

      generate!
    end

    def generate!
      FileUtils.mkdir_p(storage_dir)
      key = JWT::PQ::Key.generate(:ml_dsa_65)
      jwk = JWT::PQ::JWK.new(key)

      File.write(public_path, JSON.pretty_generate(jwk.export))
      File.write(private_path, JSON.pretty_generate(jwk.export(include_private: true)))
      File.chmod(0o600, private_path)
    ensure
      key&.destroy!
    end

    def storage_dir
      Pathname.new(ENV.fetch("JWKS_STORAGE_DIR", Rails.root.join("storage").to_s))
    end

    def public_path
      storage_dir.join("jwks_public.json")
    end

    def private_path
      storage_dir.join("jwks_private.json")
    end
  end
end
