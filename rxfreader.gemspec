Gem::Specification.new do |s|
  s.name = 'rxfreader'
  s.version = '0.1.2'
  s.summary = 'Reads a file from an HTTP address, DFS address, or local location.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/rxfreader.rb']
  s.add_runtime_dependency('gpd-request', '~> 0.3', '>=0.3.0')
  s.add_runtime_dependency('rest-client', '~> 2.1', '>=2.1.0')
  s.add_runtime_dependency('drb_fileclient', '~> 0.7', '>=0.7.3')
  s.signing_key = '../privatekeys/rxfreader.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'digital.robertson@gmail.com'
  s.homepage = 'https://github.com/jrobertson/rxfreader'
end
