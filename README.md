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

Download and install gems: 

```
bundle install
```

## Testing

This library includes a set of automated tests that exercise all functionality.

```
bundle exec rspec
```

## Example

We are using `/dev/shm` to
[emulate persistent memory](http://pmem.io/2016/02/22/pm-emulation.html)
in this simple example.

```ruby
require 'pmemkv/all'

def assert(condition)
  raise RuntimeError.new('Assert failed') unless condition
end

puts 'Starting engine'
db = Database.new('vsmap', '{"path":"/dev/shm/"}')

puts 'Putting new key'
db.put('key1', 'value1')
assert db.count == 1

puts 'Reading key back'
assert db.get('key1').eql?('value1')

puts 'Iterating existing keys'
db.put('key2', 'value2')
db.put('key3', 'value3')
db.all_strings {|k| puts "  visited: #{k}"}

puts 'Removing existing key'
db.remove('key1')
assert !db.exists('key1')

puts 'Stopping engine'
db.stop
```
