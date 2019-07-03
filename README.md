# pmemkv-ruby
Ruby bindings for pmemkv

The current API is simplified and not functionally equal to its native C/C++ counterpart.
In the future existing API may be extended in idiomatic way without preserving backward compatibility.
All known issues and limitations are logged as GitHub issues.

## Dependencies

* Ruby 2.2 or higher
* [PMDK](https://github.com/pmem/pmdk) - native persistent memory libraries
* [pmemkv](https://github.com/pmem/pmemkv) - native key/value library
* [ffi](https://github.com/ffi/ffi) - for native library integration
* Used only for testing:
  * [rspec](https://github.com/rspec/rspec) - test framework

## Installation

Start by installing [pmemkv](https://github.com/pmem/pmemkv/blob/master/INSTALLING.md) on your system.

Install Bundler:

```
gem install bundler -v '< 2.0'
```

Clone the pmemkv-ruby tree:

```
git clone https://github.com/pmem/pmemkv-ruby.git
cd pmemkv-ruby
```

Download and install gems: 

```
bundle install
```

## Testing

This library includes a set of automated tests that exercise all functionality.

```
LD_LIBRARY_PATH=path_to_your_libs bundle exec rspec
```

## Example

We are using `/dev/shm` to
[emulate persistent memory](http://pmem.io/2016/02/22/pm-emulation.html)
in this simple example.

```ruby
require './lib/pmemkv/database'

def assert(condition)
  raise RuntimeError.new('Assert failed') unless condition
end

puts 'Starting engine'
db = Database.new('vsmap', "{\"path\":\"/dev/shm\",\"size\":1073741824}")

puts 'Putting new key'
db.put('key1', 'value1')
assert db.count_all == 1

puts 'Reading key back'
assert db.get('key1').eql?('value1')

puts 'Iterating existing keys'
db.put('key2', 'value2')
db.put('key3', 'value3')
db.get_keys {|k| puts "  visited: #{k}"}

puts 'Removing existing key'
db.remove('key1')
assert !db.exists('key1')

puts 'Stopping engine'
db.stop
```
