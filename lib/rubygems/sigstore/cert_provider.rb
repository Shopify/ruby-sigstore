class Gem::Sigstore::CertProvider
  def initialize(config:, pkey:, oidp:)
    @config = config
    @pkey = pkey
    @oidp = oidp
  end

  def run
    fulcio_api.create(oidp.proof, pkey.public_key.to_der)
  end

  private

  def fulcio_api
    Gem::Sigstore::FulcioApi.new(token: oidp.token, host: config.fulcio_host)
  end

  attr_reader :config, :pkey, :oidp
end
