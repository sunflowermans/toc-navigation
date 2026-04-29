# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "jekyll-jtd-toc-nav"
  spec.version       = "0.1.0"
  spec.authors       = ["Chris"]
  spec.email         = []

  spec.summary       = "Inject page heading outline into Just the Docs sidebar nav"
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = Dir.glob("{lib,README.md,LICENSE}/**/*", File::FNM_DOTMATCH).reject { |f| f.end_with?("/.") || f.end_with?("/..") }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "jekyll", ">= 3.8"
  spec.add_runtime_dependency "nokogiri", ">= 1.13"
end

