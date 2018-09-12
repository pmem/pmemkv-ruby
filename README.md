# pmemkv-ruby
Ruby bindings for pmemkv

*This is experimental pre-release software and should not be used in
production systems. APIs and file formats may change at any time without
preserving backwards compatibility. All known issues and limitations
are logged as GitHub issues.*

## Dependencies

* Ruby 2.2 or higher
* [PMDK](https://github.com/pmem/pmdk) - native persistent memory libraries
* [pmemkv](https://github.com/pmem/pmemkv) - native key/value library
* [ffi](https://github.com/ffi/ffi) - for native library integration
* Used only for testing:
  * [rspec](https://github.com/rspec/rspec) - test framework

## Installation

Start by installing [pmemkv](https://github.com/pmem/pmemkv/blob/master/INSTALLING.md) on your system.

Add gem to your Gemfile:

```
gem 'pmemkv', :git => 'https://github.com/pmem/pmemkv-ruby.git'
```

Download gems using Bundler: `bundle install`

## Example

We are using `/dev/shm` to
[emulate persistent memory](http://pmem.io/2016/02/22/pm-emulation.html)
in this simple example.

```ruby
require 'pmemkv/all'

def assert(condition)
  raise RuntimeError.new('Assert failed') unless condition
end

puts 'Opening datastore'
kv = KVEngine.new('kvtree3', '/dev/shm/pmemkv', 1073741824) # 1 GB pool

puts 'Putting new key'
kv.put('key1', 'value1')
assert kv.count == 1

puts 'Reading key back'
assert kv.get('key1').eql?('value1')

puts 'Iterating existing keys'
kv.put('key2', 'value2')
kv.put('key3', 'value3')
kv.each_string {|k, v| puts "  visited: #{k}"}

puts 'Removing existing key'
kv.remove('key1')
assert !kv.exists('key1')

puts 'Closing datastore'
kv.close
```
