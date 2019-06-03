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
  callback :kv_all_callback, [:pointer, :int32, :pointer], :void
  callback :kv_each_callback, [:pointer, :int32, :pointer, :int32, :pointer], :void
  callback :kv_get_callback, [:pointer, :int32, :pointer], :void
  callback :kv_start_failure_callback, [:pointer, :string, :pointer, :string], :void
  attach_function :kvengine_start, [:pointer, :string, :pointer, :kv_start_failure_callback], :pointer
  attach_function :kvengine_stop, [:pointer], :void
  attach_function :kvengine_all, [:pointer, :pointer, :kv_all_callback], :void
  attach_function :kvengine_all_above, [:pointer, :pointer, :int32, :pointer, :kv_all_callback], :void
  attach_function :kvengine_all_below, [:pointer, :pointer, :int32, :pointer, :kv_all_callback], :void
  attach_function :kvengine_all_between, [:pointer, :pointer, :int32, :pointer, :int32, :pointer, :kv_all_callback], :void
  attach_function :kvengine_count, [:pointer], :int64
  attach_function :kvengine_count_above, [:pointer, :int32, :pointer], :int64
  attach_function :kvengine_count_below, [:pointer, :int32, :pointer], :int64
  attach_function :kvengine_count_between, [:pointer, :int32, :pointer, :int32, :pointer], :int64
  attach_function :kvengine_each, [:pointer, :pointer, :kv_each_callback], :void
  attach_function :kvengine_each_above, [:pointer, :pointer, :int32, :pointer, :kv_each_callback], :void
  attach_function :kvengine_each_below, [:pointer, :pointer, :int32, :pointer, :kv_each_callback], :void
  attach_function :kvengine_each_between, [:pointer, :pointer, :int32, :pointer, :int32, :pointer, :kv_each_callback], :void
  attach_function :kvengine_exists, [:pointer, :int32, :pointer], :int8
  attach_function :kvengine_get, [:pointer, :pointer, :int32, :pointer, :kv_get_callback], :void
  attach_function :kvengine_put, [:pointer, :int32, :pointer, :int32, :pointer], :int8
  attach_function :kvengine_remove, [:pointer, :int32, :pointer], :int8
  attach_function :pmemkv_config_new, [], :pointer
  attach_function :pmemkv_config_delete, [:pointer], :void
  attach_function :pmemkv_config_put, [:pointer, :string, :pointer, :int32], :int8
  attach_function :pmemkv_config_get, [:pointer, :string, :pointer, :int32, :pointer], :int8
  attach_function :pmemkv_config_from_json, [:pointer, :string], :string
end

class KVEngine

  def initialize(engine, json_string)
    @stopped = false
    config = Pmemkv.pmemkv_config_new
    raise RuntimeError.new("Cannot create a new pmemkv config") if config == nil
    err_msg = Pmemkv.pmemkv_config_from_json(config, json_string)
    raise ArgumentError.new(err_msg) if err_msg != nil
    callback = lambda do |context, engine, config, msg|
      raise ArgumentError.new(msg)
    end
    @kv = Pmemkv.kvengine_start(nil, engine, config, callback)
    Pmemkv.pmemkv_config_delete(config)
  end

  def stop
    unless @stopped
      @stopped = true
      Pmemkv.kvengine_stop(@kv)
    end
  end

  def all
    callback = lambda do |context, kb, k|
      yield(k.get_bytes(0, kb))
    end
    Pmemkv.kvengine_all(@kv, nil, callback)
  end

  def all_above(key)
    callback = lambda do |context, kb, k|
      yield(k.get_bytes(0, kb))
    end
    Pmemkv.kvengine_all_above(@kv, nil, key.bytesize, key, callback)
  end

  def all_below(key)
    callback = lambda do |context, kb, k|
      yield(k.get_bytes(0, kb))
    end
    Pmemkv.kvengine_all_below(@kv, nil, key.bytesize, key, callback)
  end

  def all_between(key1, key2)
    callback = lambda do |context, kb, k|
      yield(k.get_bytes(0, kb))
    end
    Pmemkv.kvengine_all_between(@kv, nil, key1.bytesize, key1, key2.bytesize, key2, callback)
  end

  def all_strings(encoding = 'utf-8')
    callback = lambda do |context, kb, k|
      yield(k.get_bytes(0, kb).force_encoding(encoding))
    end
    Pmemkv.kvengine_all(@kv, nil, callback)
  end

  def all_strings_above(key, encoding = 'utf-8')
    callback = lambda do |context, kb, k|
      yield(k.get_bytes(0, kb).force_encoding(encoding))
    end
    Pmemkv.kvengine_all_above(@kv, nil, key.bytesize, key, callback)
  end

  def all_strings_below(key, encoding = 'utf-8')
    callback = lambda do |context, kb, k|
      yield(k.get_bytes(0, kb).force_encoding(encoding))
    end
    Pmemkv.kvengine_all_below(@kv, nil, key.bytesize, key, callback)
  end

  def all_strings_between(key1, key2, encoding = 'utf-8')
    callback = lambda do |context, kb, k|
      yield(k.get_bytes(0, kb).force_encoding(encoding))
    end
    Pmemkv.kvengine_all_between(@kv, nil, key1.bytesize, key1, key2.bytesize, key2, callback)
  end

  def stopped?
    @stopped
  end

  def count
    Pmemkv.kvengine_count(@kv)
  end

  def count_above(key)
    Pmemkv.kvengine_count_above(@kv, key.bytesize, key)
  end

  def count_below(key)
    Pmemkv.kvengine_count_below(@kv, key.bytesize, key)
  end

  def count_between(key1, key2)
    Pmemkv.kvengine_count_between(@kv, key1.bytesize, key1, key2.bytesize, key2)
  end

  def each
    callback = lambda do |context, kb, key, vb, v|
      yield(key.get_bytes(0, kb), v.get_bytes(0, vb))
    end
    Pmemkv.kvengine_each(@kv, nil, callback)
  end

  def each_above(key)
    callback = lambda do |context, kb, k, vb, v|
      yield(k.get_bytes(0, kb), v.get_bytes(0, vb))
    end
    Pmemkv.kvengine_each_above(@kv, nil, key.bytesize, key, callback)
  end

  def each_below(key)
    callback = lambda do |context, kb, k, vb, v|
      yield(k.get_bytes(0, kb), v.get_bytes(0, vb))
    end
    Pmemkv.kvengine_each_below(@kv, nil, key.bytesize, key, callback)
  end

  def each_between(key1, key2)
    callback = lambda do |context, kb, k, vb, v|
      yield(k.get_bytes(0, kb), v.get_bytes(0, vb))
    end
    Pmemkv.kvengine_each_between(@kv, nil, key1.bytesize, key1, key2.bytesize, key2, callback)
  end

  def each_string(encoding = 'utf-8')
    callback = lambda do |context, kb, k, vb, v|
      kk = k.get_bytes(0, kb).force_encoding(encoding)
      vv = v.get_bytes(0, vb).force_encoding(encoding)
      yield(kk, vv)
    end
    Pmemkv.kvengine_each(@kv, nil, callback)
  end

  def each_string_above(key, encoding = 'utf-8')
    callback = lambda do |context, kb, k, vb, v|
      kk = k.get_bytes(0, kb).force_encoding(encoding)
      vv = v.get_bytes(0, vb).force_encoding(encoding)
      yield(kk, vv)
    end
    Pmemkv.kvengine_each_above(@kv, nil, key.bytesize, key, callback)
  end

  def each_string_below(key, encoding = 'utf-8')
    callback = lambda do |context, kb, k, vb, v|
      kk = k.get_bytes(0, kb).force_encoding(encoding)
      vv = v.get_bytes(0, vb).force_encoding(encoding)
      yield(kk, vv)
    end
    Pmemkv.kvengine_each_below(@kv, nil, key.bytesize, key, callback)
  end

  def each_string_between(key1, key2, encoding = 'utf-8')
    callback = lambda do |context, kb, k, vb, v|
      kk = k.get_bytes(0, kb).force_encoding(encoding)
      vv = v.get_bytes(0, vb).force_encoding(encoding)
      yield(kk, vv)
    end
    Pmemkv.kvengine_each_between(@kv, nil, key1.bytesize, key1, key2.bytesize, key2, callback)
  end

  def exists(key)
    Pmemkv.kvengine_exists(@kv, key.bytesize, key) == 1
  end

  def get(key)
    result = nil
    callback = lambda do |context, valuebytes, value|
      result = value.get_bytes(0, valuebytes)
    end
    Pmemkv.kvengine_get(@kv, nil, key.bytesize, key, callback)
    result
  end

  def get_string(key, encoding = 'utf-8')
    result = nil
    callback = lambda do |context, valuebytes, value|
      result = value.get_bytes(0, valuebytes).force_encoding(encoding)
    end
    Pmemkv.kvengine_get(@kv, nil, key.bytesize, key, callback)
    result
  end

  def put(key, value)
    result = Pmemkv.kvengine_put(@kv, key.bytesize, key, value.bytesize, value)
    raise RuntimeError.new("Unable to put key") if result < 0
  end

  def remove(key)
    result = Pmemkv.kvengine_remove(@kv, key.bytesize, key)
    raise RuntimeError.new("Unable to remove key") if result < 0
    (result == 1)
  end

end
