namespace :jwks do
  desc "Rotate the long-lived JWKS key pair"
  task rotate: :environment do
    old_kid = JwksKeyStore.public_jwk[:kid]
    JwksKeyStore.rotate!
    new_kid = JwksKeyStore.public_jwk[:kid]
    puts "Rotated JWKS. Old kid: #{old_kid}  New kid: #{new_kid}"
  end

  desc "Print current public JWKS"
  task show: :environment do
    puts JSON.pretty_generate(JwksKeyStore.current_jwks)
  end
end
