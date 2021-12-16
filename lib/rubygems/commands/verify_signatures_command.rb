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

require 'rubygems/command'
require 'rubygems/sigstore'

class Gem::Commands::VerifySignaturesCommand < Gem::Command
  def initialize
    super 'verify_signatures', "Verifies whether a gem has been signed via sigstore."
    add_option('--rekor-host HOST', 'Rekor host (not implemented)') do |value, options|
      options[:rekor_host] = value
    end
  end

  def execute
    gem_path = get_one_gem_name
    say "Verifying #{gem_path}"

    raise Gem::CommandLineError, "#{gem_path} is not a file" unless File.file?(gem_path)

    gemfile = Gem::Sigstore::Gemfile.new(gem_path)
    verifier = Gem::Sigstore::GemVerifier.new(
      gemfile: gemfile,
      config: Gem::Sigstore::Config.read
    )
    verifier.run
  end
end
