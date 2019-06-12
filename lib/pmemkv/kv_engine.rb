# coding: utf-8

# Copyright 2017-2019, Intel Corporation
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in
#       the documentation and/or other materials provided with the
#       distribution.
#
#     * Neither the name of the copyright holder nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require 'ffi'

module Pmemkv
  extend FFI::Library
  ffi_lib ENV['PMEMKV_LIB'].nil? ? 'libpmemkv.so' : ENV['PMEMKV_LIB']
  callback :pmemkv_all_callback, [:pointer, :uint64, :pointer], :void
  callback :pmemkv_each_callback, [:pointer, :uint64, :pointer, :uint64, :pointer], :void
  callback :pmemkv_get_callback, [:pointer, :uint64, :pointer], :void
  callback :pmemkv_start_failure_callback, [:pointer, :string, :pointer, :string], :void
  attach_function :pmemkv_open, [:pointer, :string, :pointer, :pmemkv_start_failure_callback], :pointer
  attach_function :pmemkv_close, [:pointer], :void
  attach_function :pmemkv_all, [:pointer, :pmemkv_all_callback, :pointer], :void
  attach_function :pmemkv_all_above, [:pointer, :pointer, :uint64, :pmemkv_all_callback, :pointer], :void
  attach_function :pmemkv_all_below, [:pointer, :pointer, :uint64, :pmemkv_all_callback, :pointer], :void
  attach_function :pmemkv_all_between, [:pointer, :pointer, :uint64, :pointer, :uint64, :pmemkv_all_callback, :pointer], :void
  attach_function :pmemkv_count, [:pointer], :int64
  attach_function :pmemkv_count_above, [:pointer, :pointer, :uint64], :int64
  attach_function :pmemkv_count_below, [:pointer, :pointer, :uint64], :int64
  attach_function :pmemkv_count_between, [:pointer, :pointer, :uint64, :pointer, :uint64], :int64
  attach_function :pmemkv_each, [:pointer, :pmemkv_each_callback, :pointer], :void
  attach_function :pmemkv_each_above, [:pointer, :pointer, :uint64, :pmemkv_each_callback, :pointer], :void
  attach_function :pmemkv_each_below, [:pointer, :pointer, :uint64, :pmemkv_each_callback, :pointer], :void
  attach_function :pmemkv_each_between, [:pointer, :pointer, :uint64, :pointer, :uint64, :pmemkv_each_callback, :pointer], :void
  attach_function :pmemkv_exists, [:pointer, :pointer, :uint64], :int8
  attach_function :pmemkv_get, [:pointer, :pointer, :uint64, :pmemkv_get_callback, :pointer], :void
  attach_function :pmemkv_put, [:pointer, :pointer, :uint64, :pointer, :uint64], :int8
  attach_function :pmemkv_remove, [:pointer, :pointer, :uint64], :int8
  attach_function :pmemkv_config_new, [], :pointer
  attach_function :pmemkv_config_delete, [:pointer], :void
  attach_function :pmemkv_config_put, [:pointer, :string, :pointer, :uint64], :int8
  attach_function :pmemkv_config_get, [:pointer, :string, :pointer, :uint64, :pointer], :int8
  attach_function :pmemkv_config_from_json, [:pointer, :string], :int
end

class KVEngine

  def initialize(engine, json_string)
    @stopped = false
    config = Pmemkv.pmemkv_config_new
    raise RuntimeError.new("Cannot create a new pmemkv config") if config == nil
    rv = Pmemkv.pmemkv_config_from_json(config, json_string)
    raise ArgumentError.new("Creating a pmemkv config from JSON string failed") if rv != 0
    callback = lambda do |context, engine, config, msg|
      raise ArgumentError.new(msg)
    end
    @db = Pmemkv.pmemkv_open(nil, engine, config, callback)
    Pmemkv.pmemkv_config_delete(config)
  end

  def stop
    unless @stopped
      @stopped = true
      Pmemkv.pmemkv_close(@db)
    end
  end

  def all
    callback = lambda do |k, kb, context|
      yield(k.get_bytes(0, kb))
    end
    Pmemkv.pmemkv_all(@db, callback, nil)
  end

  def all_above(key)
    callback = lambda do |k, kb, context|
      yield(k.get_bytes(0, kb))
    end
    Pmemkv.pmemkv_all_above(@db, key, key.bytesize, callback, nil)
  end

  def all_below(key)
    callback = lambda do |k, kb, context|
      yield(k.get_bytes(0, kb))
    end
    Pmemkv.pmemkv_all_below(@db, key, key.bytesize, callback, nil)
  end

  def all_between(key1, key2)
    callback = lambda do |k, kb, context|
      yield(k.get_bytes(0, kb))
    end
    Pmemkv.pmemkv_all_between(@db, key1, key1.bytesize, key2, key2.bytesize, callback, nil)
  end

  def all_strings(encoding = 'utf-8')
    callback = lambda do |k, kb, context|
      yield(k.get_bytes(0, kb).force_encoding(encoding))
    end
    Pmemkv.pmemkv_all(@db, callback, nil)
  end

  def all_strings_above(key, encoding = 'utf-8')
    callback = lambda do |k, kb, context|
      yield(k.get_bytes(0, kb).force_encoding(encoding))
    end
    Pmemkv.pmemkv_all_above(@db, key, key.bytesize, callback, nil)
  end

  def all_strings_below(key, encoding = 'utf-8')
    callback = lambda do |k, kb, context|
      yield(k.get_bytes(0, kb).force_encoding(encoding))
    end
    Pmemkv.pmemkv_all_below(@db, key, key.bytesize, callback, nil)
  end

  def all_strings_between(key1, key2, encoding = 'utf-8')
    callback = lambda do |k, kb, context|
      yield(k.get_bytes(0, kb).force_encoding(encoding))
    end
    Pmemkv.pmemkv_all_between(@db, key1, key1.bytesize, key2, key2.bytesize, callback, nil)
  end

  def stopped?
    @stopped
  end

  def count
    Pmemkv.pmemkv_count(@db)
  end

  def count_above(key)
    Pmemkv.pmemkv_count_above(@db, key, key.bytesize)
  end

  def count_below(key)
    Pmemkv.pmemkv_count_below(@db, key, key.bytesize)
  end

  def count_between(key1, key2)
    Pmemkv.pmemkv_count_between(@db, key1, key1.bytesize, key2, key2.bytesize)
  end

  def each
    callback = lambda do |k, kb, v, vb, context|
      yield(k.get_bytes(0, kb), v.get_bytes(0, vb))
    end
    Pmemkv.pmemkv_each(@db, callback, nil)
  end

  def each_above(key)
    callback = lambda do |k, kb, v, vb, context|
      yield(k.get_bytes(0, kb), v.get_bytes(0, vb))
    end
    Pmemkv.pmemkv_each_above(@db, key, key.bytesize, callback, nil)
  end

  def each_below(key)
    callback = lambda do |k, kb, v, vb, context|
      yield(k.get_bytes(0, kb), v.get_bytes(0, vb))
    end
    Pmemkv.pmemkv_each_below(@db, key, key.bytesize, callback, nil)
  end

  def each_between(key1, key2)
    callback = lambda do |k, kb, v, vb, context|
      yield(k.get_bytes(0, kb), v.get_bytes(0, vb))
    end
    Pmemkv.pmemkv_each_between(@db, key1, key1.bytesize, key2, key2.bytesize, callback, nil)
  end

  def each_string(encoding = 'utf-8')
    callback = lambda do |k, kb, v, vb, context|
      kk = k.get_bytes(0, kb).force_encoding(encoding)
      vv = v.get_bytes(0, vb).force_encoding(encoding)
      yield(kk, vv)
    end
    Pmemkv.pmemkv_each(@db, callback, nil)
  end

  def each_string_above(key, encoding = 'utf-8')
    callback = lambda do |k, kb, v, vb, context|
      kk = k.get_bytes(0, kb).force_encoding(encoding)
      vv = v.get_bytes(0, vb).force_encoding(encoding)
      yield(kk, vv)
    end
    Pmemkv.pmemkv_each_above(@db, key, key.bytesize, callback, nil)
  end

  def each_string_below(key, encoding = 'utf-8')
    callback = lambda do |k, kb, v, vb, context|
      kk = k.get_bytes(0, kb).force_encoding(encoding)
      vv = v.get_bytes(0, vb).force_encoding(encoding)
      yield(kk, vv)
    end
    Pmemkv.pmemkv_each_below(@db, key, key.bytesize, callback, nil)
  end

  def each_string_between(key1, key2, encoding = 'utf-8')
    callback = lambda do |k, kb, v, vb, context|
      kk = k.get_bytes(0, kb).force_encoding(encoding)
      vv = v.get_bytes(0, vb).force_encoding(encoding)
      yield(kk, vv)
    end
    Pmemkv.pmemkv_each_between(@db, key1, key1.bytesize, key2, key2.bytesize, callback, nil)
  end

  def exists(key)
    Pmemkv.pmemkv_exists(@db, key, key.bytesize) == 1
  end

  def get(key)
    result = nil
    callback = lambda do |value, valuebytes, context|
      result = value.get_bytes(0, valuebytes)
    end
    Pmemkv.pmemkv_get(@db, key, key.bytesize, callback, nil)
    result
  end

  def get_string(key, encoding = 'utf-8')
    result = nil
    callback = lambda do |value, valuebytes, context|
      result = value.get_bytes(0, valuebytes).force_encoding(encoding)
    end
    Pmemkv.pmemkv_get(@db, key, key.bytesize, callback, nil)
    result
  end

  def put(key, value)
    result = Pmemkv.pmemkv_put(@db, key, key.bytesize, value, value.bytesize)
    raise RuntimeError.new("Unable to put key") if result < 0
  end

  def remove(key)
    result = Pmemkv.pmemkv_remove(@db, key, key.bytesize)
    raise RuntimeError.new("Unable to remove key") if result < 0
    (result == 1)
  end

end
