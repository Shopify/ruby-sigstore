# Copyright 2021 The Sigstore Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Gem
  module Sigstore
  end
end

require 'rubygems/command'
require "rubygems/sigstore/config"
require "rubygems/sigstore/crypto"
require "rubygems/sigstore/fulcio_api"
require "rubygems/sigstore/openid"
require "rubygems/sigstore/gemfile"

require 'json/jwt'
require "launchy"
require "openid_connect"
require "socket"

class Gem::Commands::SignCommand < Gem::Command
  def initialize
    super "sign", "Sign a gem"
  end

  def arguments # :nodoc:
    "GEMNAME        name of gem to sign"
  end

  def defaults_str # :nodoc:
    ""
  end

  def usage # :nodoc:
    "gem sign GEMNAME"
  end

  def execute
    config = Gem::Sigstore::Config.read
    priv_key, _pub_key, enc_pub_key = Gem::Sigstore::Crypto.new.generate_keys
    proof, access_token = Gem::Sigstore::OpenID.new(priv_key).get_token

    fulcio_api = Gem::Sigstore::FulcioApi.new(token: access_token, host: config.fulcio_host)
    cert_response = fulcio_api.create(proof, enc_pub_key)

    puts "Fulcio cert chain"
    print cert_response
    puts ""

    gem_file = Gem::Sigstore::Gemfile.new(get_one_gem_name)
    gem_file_signature = priv_key.sign gem_file.digest, gem_file.content

    content = <<~CONTENT

      sigstore signing operation complete."

      sending signiture & certificate chain to rekor."
    CONTENT
    puts content

    data = Gem::Sigstore::RekorApi::Data.new(gem_file.digest, gem_file_signature, gem_file.content)
    rekor_api = Gem::Sigstore::RekorApi.new(host: config.fulcio_host)
    rekor_response = rekor_api.create(cert_response, data)
    puts "rekor response: "
    pp rekor_response
  end
end
