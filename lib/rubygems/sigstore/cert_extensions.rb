module Gem::Sigstore::CertExtensions
  def extension(oid)
    extensions_hash[oid]
  end

  private

  def extensions_hash
    @extensions_hash ||= extensions.each_with_object({}) do |ext, hash|
      hash[ext.oid] = ext.value
    end
  end
end
