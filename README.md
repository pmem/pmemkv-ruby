# pmemkv-ruby
Ruby bindings for pmemkv

*This is experimental pre-release software and should not be used in
production systems. APIs and file formats may change at any time without
preserving backwards compatibility. All known issues and limitations
are logged as GitHub issues.*

## Dependencies

* Ruby 2.2 or higher
* [pmemkv](https://github.com/pmem/pmemkv) - native key/value library
* [ffi](https://github.com/ffi/ffi) - for native library integration
* Used only for testing:
  * [rspec](https://github.com/rspec/rspec) - test framework

## Installation

Start by installing [pmemkv](https://github.com/pmem/pmemkv#installation) on your system.

Add gem to your Gemfile:

```
gem 'pmemkv', :git => 'https://github.com/pmem/pmemkv-ruby.git'
```

Download gems using Bundler: `bundle install`

## Sample Code

We are using `/dev/shm` to
[emulate persistent memory](http://pmem.io/2016/02/22/pm-emulation.html)
in this simple example.

```
require 'pmemkv/all'

kv = KVEngine.new('/dev/shm/mykv', 8388608) # 8 MB
kv.put('key1', 'value1')
expect(kv.get('key1')).to eql 'value1'
kv.remove('key1')
kv.close
```
