require "test_helper"

class JwksKeyStoreTest < ActiveSupport::TestCase
  setup do
    @storage_dir = Dir.mktmpdir("jwks-test")
    ENV["JWKS_STORAGE_DIR"] = @storage_dir
    # Files do not exist yet, so the next call should generate them.
  end

  teardown do
    FileUtils.remove_entry(@storage_dir) if @storage_dir && File.exist?(@storage_dir)
    ENV.delete("JWKS_STORAGE_DIR")
  end

  test "generates a fresh key on first access" do
    jwks = JwksKeyStore.current_jwks
    assert_equal 1, jwks[:keys].size
    key = jwks[:keys].first
    assert_equal "AKP", key[:kty]
    assert_equal "ML-DSA-65", key[:alg]
    assert key[:pub].present?
    assert key[:kid].present?
    refute key.key?(:priv)
  end

  test "persists keys across calls" do
    first = JwksKeyStore.public_jwk
    second = JwksKeyStore.public_jwk
    assert_equal first[:kid], second[:kid]
  end

  test "writes private key with 0600 permissions" do
    JwksKeyStore.current_jwks
    private_path = File.join(@storage_dir, "jwks_private.json")
    assert File.exist?(private_path)
    mode = File.stat(private_path).mode & 0o777
    assert_equal 0o600, mode
  end

  test "rotate! changes the kid" do
    old_kid = JwksKeyStore.public_jwk[:kid]
    JwksKeyStore.rotate!
    new_kid = JwksKeyStore.public_jwk[:kid]
    refute_equal old_kid, new_kid
  end
end
