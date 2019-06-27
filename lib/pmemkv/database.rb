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

PMEMKV_STATUS_OK = 0
PMEMKV_STATUS_FAILED = 1
PMEMKV_STATUS_NOT_FOUND = 2
PMEMKV_STATUS_NOT_SUPPORTED = 3
PMEMKV_STATUS_INVALID_ARGUMENT = 4
PMEMKV_STATUS_CONFIG_PARSING_ERROR = 5

# two classes used to pass a result by reference: https://github.com/ffi/ffi/wiki/Pointers
# pointer to pointer
class PtrPtr < FFI::Struct
    layout  :value, :pointer
end

# pointer to int64
class Int64Ptr < FFI::Struct
    layout  :value, :int64
end

module Pmemkv
  extend FFI::Library
  ffi_lib ENV['PMEMKV_LIB'].nil? ? 'libpmemkv.so' : ENV['PMEMKV_LIB']
  # callback :pmemkv_all_callback, [:pointer, :uint64, :pointer], :void
  callback :pmemkv_get_kv_callback, [:pointer, :uint64, :pointer, :uint64, :pointer], :void
  callback :pmemkv_get_v_callback, [:pointer, :uint64, :pointer], :void
  callback :pmemkv_start_failure_callback, [:pointer, :string, :pointer, :string], :void
  attach_function :pmemkv_open, [:pointer, :string, :pointer, PtrPtr], :int
  attach_function :pmemkv_close, [:pointer], :void
  # attach_function :pmemkv_all, [:pointer, :pmemkv_all_callback, :pointer], :int
  # attach_function :pmemkv_all_above, [:pointer, :pointer, :uint64, :pmemkv_all_callback, :pointer], :int
  # attach_function :pmemkv_all_below, [:pointer, :pointer, :uint64, :pmemkv_all_callback, :pointer], :int
  # attach_function :pmemkv_all_between, [:pointer, :pointer, :uint64, :pointer, :uint64, :pmemkv_all_callback, :pointer], :int
  attach_function :pmemkv_count_all, [:pointer, Int64Ptr], :int
  attach_function :pmemkv_count_above, [:pointer, :pointer, :uint64, Int64Ptr], :int
  attach_function :pmemkv_count_below, [:pointer, :pointer, :uint64, Int64Ptr], :int
  attach_function :pmemkv_count_between, [:pointer, :pointer, :uint64, :pointer, :uint64, Int64Ptr], :int
  attach_function :pmemkv_get_all, [:pointer, :pmemkv_get_kv_callback, :pointer], :int
  attach_function :pmemkv_get_above, [:pointer, :pointer, :uint64, :pmemkv_get_kv_callback, :pointer], :int
  attach_function :pmemkv_get_below, [:pointer, :pointer, :uint64, :pmemkv_get_kv_callback, :pointer], :int
  attach_function :pmemkv_get_between, [:pointer, :pointer, :uint64, :pointer, :uint64, :pmemkv_get_kv_callback, :pointer], :int
  attach_function :pmemkv_exists, [:pointer, :pointer, :uint64], :int
  attach_function :pmemkv_get, [:pointer, :pointer, :uint64, :pmemkv_get_v_callback, :pointer], :int
  attach_function :pmemkv_put, [:pointer, :pointer, :uint64, :pointer, :uint64], :int
  attach_function :pmemkv_remove, [:pointer, :pointer, :uint64], :int
  attach_function :pmemkv_config_new, [], :pointer
  attach_function :pmemkv_config_delete, [:pointer], :void
  attach_function :pmemkv_config_put_data, [:pointer, :string, :pointer, :uint64], :int
  attach_function :pmemkv_config_put_object, [:pointer, :string, :pointer, :pointer], :int
  attach_function :pmemkv_config_put_uint64, [:pointer, :string, :uint64], :int
  attach_function :pmemkv_config_put_int64, [:pointer, :string, :int64], :int
  attach_function :pmemkv_config_put_double, [:pointer, :string, :double], :int
  attach_function :pmemkv_config_put_string, [:pointer, :string, :string], :int
  attach_function :pmemkv_config_get_data, [:pointer, :string, :pointer, :uint64], :int
  attach_function :pmemkv_config_get_object, [:pointer, :string, :pointer], :int
  attach_function :pmemkv_config_get_uint64, [:pointer, :string, :uint64], :int
  attach_function :pmemkv_config_get_int64, [:pointer, :string, :int64], :int
  attach_function :pmemkv_config_get_double, [:pointer, :string, :pointer], :int
  attach_function :pmemkv_config_get_string, [:pointer, :string, :string], :int
  attach_function :pmemkv_config_from_json, [:pointer, :string], :int
end

class Database

  def initialize(engine, json_string)
    @stopped = false
    config = Pmemkv.pmemkv_config_new
    raise RuntimeError.new("Allocating a new pmemkv config failed") if config == nil

    rv = Pmemkv.pmemkv_config_from_json(config, json_string)
    if rv != 0
      Pmemkv.pmemkv_config_delete(config)
      raise ArgumentError.new("Creating a pmemkv config from JSON string failed")
    end

    # passing a result by reference: https://github.com/ffi/ffi/wiki/Pointers
    dbl = PtrPtr.new
    rv = Pmemkv.pmemkv_open(nil, engine, config, dbl)
    Pmemkv.pmemkv_config_delete(config)
    raise ArgumentError.new("pmemkv_open failed") if rv != 0
    @db = dbl[:value]
  end

  def stop
    unless @stopped
      @stopped = true
      Pmemkv.pmemkv_close(@db)
    end
  end

  # def all
  #   callback = lambda do |k, kb, context|
  #     yield(k.get_bytes(0, kb))
  #   end
  #   result = Pmemkv.pmemkv_all(@db, callback, nil)
  #   raise RuntimeError.new("pmemkv_all() failed") if result == PMEMKV_STATUS_FAILED
  #   result
  # # end

  # def all_above(key)
  #   callback = lambda do |k, kb, context|
  #     yield(k.get_bytes(0, kb))
  #   end
  #   result = Pmemkv.pmemkv_all_above(@db, key, key.bytesize, callback, nil)
  #   raise RuntimeError.new("pmemkv_all_above() failed") if result == PMEMKV_STATUS_FAILED
  #   result
  # end

  # def all_below(key)
  #   callback = lambda do |k, kb, context|
  #     yield(k.get_bytes(0, kb))
  #   end
  #   result = Pmemkv.pmemkv_all_below(@db, key, key.bytesize, callback, nil)
  #   raise RuntimeError.new("pmemkv_all_below() failed") if result == PMEMKV_STATUS_FAILED
  #   result
  # end

  # def all_between(key1, key2)
  #   callback = lambda do |k, kb, context|
  #     yield(k.get_bytes(0, kb))
  #   end
  #   result = Pmemkv.pmemkv_all_between(@db, key1, key1.bytesize, key2, key2.bytesize, callback, nil)
  #   raise RuntimeError.new("pmemkv_all_between() failed") if result == PMEMKV_STATUS_FAILED
  #   result
  # end

  # def all_strings(encoding = 'utf-8')
  #   callback = lambda do |k, kb, context|
  #     yield(k.get_bytes(0, kb).force_encoding(encoding))
  #   end
  #   result = Pmemkv.pmemkv_all(@db, callback, nil)
  #   raise RuntimeError.new("pmemkv_all() failed") if result == PMEMKV_STATUS_FAILED
  #   result
  # end

  # def all_strings_above(key, encoding = 'utf-8')
  #   callback = lambda do |k, kb, context|
  #     yield(k.get_bytes(0, kb).force_encoding(encoding))
  #   end
  #   result = Pmemkv.pmemkv_all_above(@db, key, key.bytesize, callback, nil)
  #   raise RuntimeError.new("pmemkv_all_above() failed") if result == PMEMKV_STATUS_FAILED
  #   result
  # end

  # def all_strings_below(key, encoding = 'utf-8')
  #   callback = lambda do |k, kb, context|
  #     yield(k.get_bytes(0, kb).force_encoding(encoding))
  #   end
  #   result = Pmemkv.pmemkv_all_below(@db, key, key.bytesize, callback, nil)
  #   raise RuntimeError.new("pmemkv_all_below() failed") if result == PMEMKV_STATUS_FAILED
  #   result
  # end

  # def all_strings_between(key1, key2, encoding = 'utf-8')
  #   callback = lambda do |k, kb, context|
  #     yield(k.get_bytes(0, kb).force_encoding(encoding))
  #   end
  #   result = Pmemkv.pmemkv_all_between(@db, key1, key1.bytesize, key2, key2.bytesize, callback, nil)
  #   raise RuntimeError.new("pmemkv_all_between() failed") if result == PMEMKV_STATUS_FAILED
  #   result
  # end

  def stopped?
    @stopped
  end

  def count_all
    cnt = Int64Ptr.new
    rv = Pmemkv.pmemkv_count_all(@db, cnt)
    raise RuntimeError.new("pmemkv_count_all() failed") if rv != PMEMKV_STATUS_OK
    cnt[:value]
  end

  def count_above(key)
    cnt = Int64Ptr.new
    rv = Pmemkv.pmemkv_count_above(@db, key, key.bytesize, cnt)
    raise RuntimeError.new("pmemkv_count_above() failed") if rv != PMEMKV_STATUS_OK
    cnt[:value]
  end

  def count_below(key)
    cnt = Int64Ptr.new
    rv = Pmemkv.pmemkv_count_below(@db, key, key.bytesize, cnt)
    raise RuntimeError.new("pmemkv_count_below() failed") if rv != PMEMKV_STATUS_OK
    cnt[:value]
  end

  def count_between(key1, key2)
    cnt = Int64Ptr.new
    rv = Pmemkv.pmemkv_count_between(@db, key1, key1.bytesize, key2, key2.bytesize, cnt)
    raise RuntimeError.new("pmemkv_count_between() failed") if rv != PMEMKV_STATUS_OK
    cnt[:value]
  end

  def get_all
    callback = lambda do |k, kb, v, vb, context|
      yield(k.get_bytes(0, kb), v.get_bytes(0, vb))
    end
    result = Pmemkv.pmemkv_get_all(@db, callback, nil)
    raise RuntimeError.new("pmemkv_get_all() failed") if result == PMEMKV_STATUS_FAILED
    result
  end

  def get_above(key)
    callback = lambda do |k, kb, v, vb, context|
      yield(k.get_bytes(0, kb), v.get_bytes(0, vb))
    end
    result = Pmemkv.pmemkv_get_above(@db, key, key.bytesize, callback, nil)
    raise RuntimeError.new("pmemkv_get_above() failed") if result == PMEMKV_STATUS_FAILED
    result
  end

  def get_below(key)
    callback = lambda do |k, kb, v, vb, context|
      yield(k.get_bytes(0, kb), v.get_bytes(0, vb))
    end
    result = Pmemkv.pmemkv_get_below(@db, key, key.bytesize, callback, nil)
    raise RuntimeError.new("pmemkv_get_below() failed") if result == PMEMKV_STATUS_FAILED
    result
  end

  def get_between(key1, key2)
    callback = lambda do |k, kb, v, vb, context|
      yield(k.get_bytes(0, kb), v.get_bytes(0, vb))
    end
    result = Pmemkv.pmemkv_get_between(@db, key1, key1.bytesize, key2, key2.bytesize, callback, nil)
    raise RuntimeError.new("pmemkv_get_between() failed") if result == PMEMKV_STATUS_FAILED
    result
  end

  def get_keys(encoding = 'utf-8')
    callback = lambda do |k, kb, v, vb, context|
      yield(k.get_bytes(0, kb).force_encoding(encoding))
    end
    result = Pmemkv.pmemkv_get_all(@db, callback, nil)
    raise RuntimeError.new("pmemkv_get_all() failed") if result == PMEMKV_STATUS_FAILED
    result
  end

  def get_all_string(encoding = 'utf-8')
    callback = lambda do |k, kb, v, vb, context|
      kk = k.get_bytes(0, kb).force_encoding(encoding)
      vv = v.get_bytes(0, vb).force_encoding(encoding)
      yield(kk, vv)
    end
    result = Pmemkv.pmemkv_get_all(@db, callback, nil)
    raise RuntimeError.new("pmemkv_get_all() failed") if result == PMEMKV_STATUS_FAILED
    result
  end

  def get_string_above(key, encoding = 'utf-8')
    callback = lambda do |k, kb, v, vb, context|
      kk = k.get_bytes(0, kb).force_encoding(encoding)
      vv = v.get_bytes(0, vb).force_encoding(encoding)
      yield(kk, vv)
    end
    result = Pmemkv.pmemkv_get_above(@db, key, key.bytesize, callback, nil)
    raise RuntimeError.new("pmemkv_get_above() failed") if result == PMEMKV_STATUS_FAILED
    result
  end

  def get_string_below(key, encoding = 'utf-8')
    callback = lambda do |k, kb, v, vb, context|
      kk = k.get_bytes(0, kb).force_encoding(encoding)
      vv = v.get_bytes(0, vb).force_encoding(encoding)
      yield(kk, vv)
    end
    result = Pmemkv.pmemkv_get_below(@db, key, key.bytesize, callback, nil)
    raise RuntimeError.new("pmemkv_get_below() failed") if result == PMEMKV_STATUS_FAILED
    result
  end

  def get_string_between(key1, key2, encoding = 'utf-8')
    callback = lambda do |k, kb, v, vb, context|
      kk = k.get_bytes(0, kb).force_encoding(encoding)
      vv = v.get_bytes(0, vb).force_encoding(encoding)
      yield(kk, vv)
    end
    result = Pmemkv.pmemkv_get_between(@db, key1, key1.bytesize, key2, key2.bytesize, callback, nil)
    raise RuntimeError.new("pmemkv_get_between() failed") if result == PMEMKV_STATUS_FAILED
    result
  end

  def exists(key)
    result = Pmemkv.pmemkv_exists(@db, key, key.bytesize)
    raise RuntimeError.new("pmemkv_exists() failed") if result == PMEMKV_STATUS_FAILED
    (result == PMEMKV_STATUS_OK)
  end

  def get(key)
    result = nil
    callback = lambda do |value, valuebytes, context|
      result = value.get_bytes(0, valuebytes)
    end
    rv = Pmemkv.pmemkv_get(@db, key, key.bytesize, callback, nil)
    raise RuntimeError.new("pmemkv_get() failed") if rv == PMEMKV_STATUS_FAILED
    result
  end

  def get_string(key, encoding = 'utf-8')
    result = nil
    callback = lambda do |value, valuebytes, context|
      result = value.get_bytes(0, valuebytes).force_encoding(encoding)
    end
    rv = Pmemkv.pmemkv_get(@db, key, key.bytesize, callback, nil)
    raise RuntimeError.new("pmemkv_get() failed") if rv == PMEMKV_STATUS_FAILED
    result
  end

  def put(key, value)
    result = Pmemkv.pmemkv_put(@db, key, key.bytesize, value, value.bytesize)
    raise RuntimeError.new("pmemkv_put() failed") if result == PMEMKV_STATUS_FAILED
    result
  end

  def remove(key)
    rv = Pmemkv.pmemkv_remove(@db, key, key.bytesize)
    raise RuntimeError.new("pmemkv_remove() failed") if rv == PMEMKV_STATUS_FAILED
    (rv == PMEMKV_STATUS_OK)
  end

end
