# coding: utf-8

Gem::Specification.new do |spec|
  spec.name = 'pmemkv'
  spec.version = '0.8'

  spec.summary = 'Ruby bindings for pmemkv'
  spec.description = spec.summary
  spec.homepage = 'https://github.com/pmem/pmemkv-ruby'
  spec.license = 'BSD-3-Clause'
  spec.authors = ['szyrom']

  spec.files = `git ls-files -z ./lib`.split("\x0")
  spec.require_paths = ['lib']

  spec.required_ruby_version = '~> 2.2'
  spec.add_development_dependency 'rspec'
  spec.add_runtime_dependency 'ffi'
end
