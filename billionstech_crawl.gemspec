# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "billionstech_crawl/version"

Gem::Specification.new do |spec|
  spec.name          = "billionstech_crawl"
  spec.version       = BillionstechCrawl::VERSION
  spec.authors       = ["yacheng.zhao"]
  spec.email         = ["yacheng.zhao@ihaveu.net"]

  spec.summary       = %q{sogou weixin crawl}
  spec.description   = %q{微信公众号爬虫}
  spec.homepage      = "https://github.com/zhzyc142/billionstech_crawl"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://github.com/zhzyc142/billionstech_crawl"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = Dir['{bin,lib}/**/*']
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'nokogiri'
  spec.add_development_dependency  'faraday'
  spec.add_development_dependency  'pry'
  spec.add_development_dependency  'uuidtools'
end
