module Gem
  module Sigstore
    module OpenID
    end
  end
end

require "rubygems/sigstore/crypto"

require 'json/jwt'

class Gem::Sigstore::OpenID::Static
  def initialize(priv_key, token)
    @priv_key = priv_key
    @unparsed_token = token
  end

  # https://www.youtube.com/watch?v=ZsgA77j5LyY
  def proof
    @proof ||= create_proof
  end

  def token
    @token ||= parse_token
  end

  private

  def create_proof
    pkey.sign_proof(subject)
  end

  def pkey
    @pkey ||= Gem::Sigstore::PKey.new(private_key: @priv_key)
  end

  def parse_token
    begin
      decoded_access_token = JSON::JWT.decode(@unparsed_token.to_s)
      JSON.parse(decoded_access_token.to_json)
    rescue JSON::JWS::VerificationFailed => e
      abort 'JWT Verification Failed: ' + e.to_s
    end
  end

  def subject
    if token["email"]
      # ensure that the OIDC provider has verified the email address
      # note: this may have happened some time in the past
      if token["email_verified"] != true
        abort 'Email address in OIDC token has not been verified by provider'
      end
      return token["email"]
    end

    if token["subject"].empty?
      abort 'No subject found in claims'
    end

    token["subject"]
  end
end
