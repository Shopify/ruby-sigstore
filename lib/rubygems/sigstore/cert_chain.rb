require "open-uri"
require "rubygems/sigstore/cert_extensions"

class Gem::Sigstore::CertChain
  PATTERN = /-----BEGIN CERTIFICATE-----(?:.|\n)+?-----END CERTIFICATE-----/.freeze

  def initialize(cert_pem)
    @cert_pem = cert_pem
  end

  def certificates
    @certificates ||= build_chain
  end

  def signing_cert
    certificates.last
  end

  def root_cert
    certificates.first
  end

  private

  def build_chain
    deserialize.tap do |chain|
      while chain.first&.extension("authorityInfoAccess") do
        chain.prepend(retrieve_issuer_cert(chain.first))
      end
    end
  end

  def deserialize
    return [] unless @cert_pem
    @cert_pem.scan(PATTERN).map do |cert|
      cert = OpenSSL::X509::Certificate.new(cert)
      cert.extend(Gem::Sigstore::CertExtensions)
      cert
    end
  end

  def retrieve_issuer_cert(cert)
    aia = cert.extension("authorityInfoAccess")
    issuer_cert_url = aia.match(/http\S+/).to_s
    raise "unsupported authorityInfoAccess value #{aia}" if issuer_cert_url.empty?

    cert_pem = URI.open(issuer_cert_url).read
    issuer = OpenSSL::X509::Certificate.new(cert_pem)
    issuer.extend(Gem::Sigstore::CertExtensions)
    issuer
  end
end
