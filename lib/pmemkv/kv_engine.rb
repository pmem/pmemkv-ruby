# coding: utf-8

# Copyright 2017-2018, Intel Corporation
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
  attach_function :kvengine_start, [:string, :string], :pointer
  attach_function :kvengine_stop, [:pointer], :void
  attach_function :kvengine_all, [:pointer, :pointer, :kv_all_callback], :void
  attach_function :kvengine_count, [:pointer], :int64
  attach_function :kvengine_each, [:pointer, :pointer, :kv_each_callback], :void
  attach_function :kvengine_exists, [:pointer, :int32, :pointer], :int8
  attach_function :kvengine_get, [:pointer, :pointer, :int32, :pointer, :kv_get_callback], :void
  attach_function :kvengine_put, [:pointer, :int32, :pointer, :int32, :pointer], :int8
  attach_function :kvengine_remove, [:pointer, :int32, :pointer], :int8
end

class KVEngine

  def initialize(engine, config)
    @stopped = false
    @kv = Pmemkv.kvengine_start(engine, config)
    raise ArgumentError.new('unable to start engine') if @kv.null?
  end

  def stop
    unless @stopped
      @stopped = true
      Pmemkv.kvengine_stop(@kv)
    end
  end

  def all
    callback = lambda do |context, keybytes, key|
      yield(key.get_bytes(0, keybytes))
    end
    Pmemkv.kvengine_all(@kv, nil, callback)
  end

  def all_strings(encoding = 'utf-8')
    callback = lambda do |context, keybytes, key|
      yield(key.get_bytes(0, keybytes).force_encoding(encoding))
    end
    Pmemkv.kvengine_all(@kv, nil, callback)
  end

  def stopped?
    @stopped
  end

  def count
    Pmemkv.kvengine_count(@kv)
  end

  def each
    callback = lambda do |context, keybytes, key, valuebytes, value|
      yield(key.get_bytes(0, keybytes), value.get_bytes(0, valuebytes))
    end
    Pmemkv.kvengine_each(@kv, nil, callback)
  end

  def each_string(encoding = 'utf-8')
    callback = lambda do |context, keybytes, key, valuebytes, value|
      k = key.get_bytes(0, keybytes).force_encoding(encoding)
      v = value.get_bytes(0, valuebytes).force_encoding(encoding)
      yield(k, v)
    end
    Pmemkv.kvengine_each(@kv, nil, callback)
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
    raise RuntimeError.new("unable to put key: #{key}") if result < 0
  end

  def remove(key)
    result = Pmemkv.kvengine_remove(@kv, key.bytesize, key)
    raise RuntimeError.new("unable to remove key: #{key}") if result < 0
    (result == 1)
  end

end
