# coding: utf-8

# Copyright 2017, Intel Corporation
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
  ffi_lib '/usr/local/lib/libpmemkv.so'
  attach_function :kvengine_open, [:string, :string, :size_t], :pointer
  attach_function :kvengine_close, [:pointer], :void
  attach_function :kvengine_get_ffi, [:pointer], :int8
  attach_function :kvengine_put_ffi, [:pointer], :int8
  attach_function :kvengine_remove_ffi, [:pointer], :int8
end

class KVEngine

  def initialize(engine, path, size=8388608, limit=1024)
    @closed = false
    @kv = Pmemkv.kvengine_open(engine, path, size)
    raise ArgumentError.new('unable to open persistent pool') if @kv.null?
    @limit=limit
  end

  def close
    unless @closed
      @closed = true
      Pmemkv.kvengine_close(@kv)
    end
  end

  def closed?
    @closed
  end

  def get(key)
    keybytes = key.bytesize

    buf = engine_buffer
    buf.put_pointer(0, @kv)
    buf.put_int32(8, @limit)
    buf.put_int32(12, keybytes)
    buf.put_int32(16, 0)
    buf.put_bytes(20, key, 0, keybytes)
    buf.put_int32(20 + keybytes, 0)

    result = Pmemkv.kvengine_get_ffi(buf)
    if result == 0
      nil
    elsif result > 0
      buf.get_bytes(20 + keybytes, buf.get_int32(16)).force_encoding('utf-8')
    else
      raise RuntimeError.new("unable to get key: #{key}")
    end
  end

  def put(key, value)
    keybytes = key.bytesize
    valuebytes = value.bytesize

    buf = engine_buffer
    buf.put_pointer(0, @kv)
    buf.put_int32(12, keybytes)
    buf.put_int32(16, valuebytes)
    buf.put_bytes(20, key, 0, keybytes)
    buf.put_bytes(20 + keybytes, value, 0, valuebytes)

    result = Pmemkv.kvengine_put_ffi(buf)
    raise RuntimeError.new("unable to put key: #{key}") if result != 1
  end

  def remove(key)
    keybytes = key.bytesize

    buf = engine_buffer
    buf.put_pointer(0, @kv)
    buf.put_int32(12, keybytes)
    buf.put_bytes(20, key, 0, keybytes)
    buf.put_int32(20 + keybytes, 0)

    Pmemkv.kvengine_remove_ffi(buf)
  end

  private

  def engine_buffer
    buf = Thread.current[:kv_engine_buf]
    unless buf
      buf = FFI::MemoryPointer.new(:pointer, @limit)
      Thread.current[:kv_engine_buf] = buf
    end
    buf
  end

end
