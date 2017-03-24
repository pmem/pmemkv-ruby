# pmemkv-ruby
Ruby bindings for pmemkv

*This is experimental pre-release software and should not be used in
production systems. APIs and file formats may change at any time without
preserving backwards compatibility. All known issues and limitations
are logged as GitHub issues.*

## Dependencies

* Ruby 2.2 or higher
* [ffi](https://github.com/ffi/ffi) - for native library integration
* [rspec](https://github.com/rspec/rspec) - for automated testing

## Installation

Add this line to your Gemfile:

```
gem 'pmemkv', :git => 'https://github.com/pmem/pmemkv-ruby.git'
```

Then install using Bundler: `bundle install`
