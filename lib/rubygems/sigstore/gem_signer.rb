class Gem::Sigstore::GemSigner
  include Gem::UserInteraction

  Data = Struct.new(:digest, :signature, :raw)

  def initialize(gemfile:, config:, token: nil)
    @gemfile = gemfile
    @config = config
    @token = token
  end

  def run
    pkey = Gem::Sigstore::PKey.new
    oidp = if token
             Gem::Sigstore::OpenID::Dynamic.new(pkey.private_key, token)
           else
             Gem::Sigstore::OpenID::Static.new(pkey.private_key)
           end
    cert = Gem::Sigstore::CertProvider.new(config: config, pkey: pkey, oidp: oidp).run

    yield if block_given?

    say "Fulcio certificate chain"
    say cert
    say
    say "Sending gem digest, signature & certificate chain to transparency log."

    Gem::Sigstore::FileSigner.new(
      file: gemfile,
      pkey: pkey,
      transparency_log: Gem::Sigstore::RekorApi.new(host: config.rekor_host),
      cert: cert
    ).run
  end

  private

  attr_reader :gemfile, :config
end
