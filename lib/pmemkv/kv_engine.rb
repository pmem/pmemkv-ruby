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

class IntPtr < FFI::Struct
  layout :value, :int32
end

module Pmemkv
  extend FFI::Library
  ffi_lib '/usr/local/lib/libpmemkv.so'
  attach_function :kvengine_open, [:string, :string, :size_t], :pointer
  attach_function :kvengine_close, [:pointer], :void
  attach_function :kvengine_get, [:pointer, :string, :int32, :pointer, IntPtr], :int8
  attach_function :kvengine_put, [:pointer, :string, :pointer, IntPtr], :int8
  attach_function :kvengine_remove, [:pointer, :string], :void
end

class KVEngine

  def initialize(engine, path, size, options={})
    @closed = false
    @kv = Pmemkv.kvengine_open(engine, path, size)
    raise ArgumentError.new('unable to open persistent pool') if @kv.null?
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
    limit = 1024
    value = FFI::MemoryPointer.new(:pointer, limit)
    valuebytes = IntPtr.new

    result = Pmemkv.kvengine_get(@kv, key, limit, value, valuebytes)
    if result == 0
      nil
    elsif result > 0
      value.get_bytes(0, valuebytes[:value]).force_encoding('utf-8')
    else
      raise RuntimeError.new('unable to get value')
    end
  end

  def put(key, new_value)
    limit = 1024
    value = FFI::MemoryPointer.new(:pointer, limit)
    valuebytes = IntPtr.new

    bytesize = new_value.bytesize
    value.put_bytes(0, new_value, 0, bytesize)
    valuebytes[:value] = bytesize
    result = Pmemkv.kvengine_put(@kv, key, value, valuebytes)
    raise RuntimeError.new('unable to put value') if result != 1
  end

  def remove(key)
    Pmemkv.kvengine_remove(@kv, key)
  end

end
