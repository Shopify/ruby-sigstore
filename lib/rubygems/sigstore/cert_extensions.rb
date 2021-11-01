module Gem::Sigstore::CertExtensions
  def method_missing(method, *args, &block)
    extensions_hash.fetch(method.to_s) { |_| super }
  end

  def extension(oid)
    extensions_hash[snake_case(oid)]
  end

  private

  def extensions_hash
    @extensions_hash ||= extensions.each_with_object({}) do |ext, hash|
      hash[snake_case(ext.oid)] = ext.value
    end
  end

  def snake_case(oid)
    oid
      .gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
      .gsub(/([a-z\d])([A-Z])/,'\1_\2')
      .tr("-", "_")
      .downcase
  end
end
