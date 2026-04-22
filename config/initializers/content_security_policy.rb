# Be sure to restart your server when you modify this file.

# Application-wide Content Security Policy. The surface is small: Rails
# serves its own CSS/JS via Propshaft + importmap; Google Fonts is the
# only third-party origin; the debugger only fetches same-origin endpoints
# (/verify and /samples/:id).
#
# Importmap emits two inline <script> tags (the import map itself and the
# module bootstrap). Rails injects the nonce into those tags when a nonce
# generator is configured, so script-src stays nonce-gated instead of
# falling back to 'unsafe-inline'.
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src     :self
    policy.base_uri        :self
    policy.object_src      :none
    policy.frame_ancestors :none
    policy.form_action     :self

    policy.script_src  :self
    policy.style_src   :self, "https://fonts.googleapis.com"
    policy.font_src    :self, "https://fonts.gstatic.com"
    policy.img_src     :self, :data
    policy.connect_src :self
  end

  config.content_security_policy_nonce_generator = ->(request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src style-src]
end
