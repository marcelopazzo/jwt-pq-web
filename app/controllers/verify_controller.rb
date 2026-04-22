class VerifyController < ApplicationController
  include SizeLimited

  ALLOWED_ALGS = %w[
    ML-DSA-44 ML-DSA-65 ML-DSA-87
    EdDSA+ML-DSA-44 EdDSA+ML-DSA-65 EdDSA+ML-DSA-87
  ].freeze

  MAX_TOKEN_BYTES = 16_384
  MAX_PUBKEY_BYTES = 8_192

  # /verify is a stateless public API: no session, no auth, no DB write, no
  # side effect beyond returning the verification result computed from the
  # posted JSON. CSRF protection guards against cross-origin state changes
  # tied to a victim's session — there is no such state here — so skipping
  # forgery protection on :create is intentional and the endpoint is free to
  # be called from curl / third-party clients.
  skip_forgery_protection only: :create

  rate_limit to: 10, within: 1.minute, by: -> { request.remote_ip }, with: -> { render_rate_limited }, only: :create

  def create
    token = check_size!(params.require(:token).to_s, MAX_TOKEN_BYTES, "token")
    pubkey = check_size!(params.require(:pubkey).to_s, MAX_PUBKEY_BYTES, "pubkey")

    result = Verifier.new(token: token, pubkey: pubkey, allowed_algs: ALLOWED_ALGS).call

    render json: result.as_json, status: result.http_status
  rescue ActionController::ParameterMissing => e
    render json: { valid: false, error: "missing_parameter", detail: e.param }, status: :bad_request
  rescue PayloadTooLarge => e
    render json: { valid: false, error: "payload_too_large", detail: e.field }, status: :content_too_large
  end

  private

  def render_rate_limited
    render json: { valid: false, error: "rate_limited" }, status: :too_many_requests
  end
end
