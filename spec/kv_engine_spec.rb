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

require 'pmemkv/all'

ENGINE = 'kvtree2'
PATH = '/dev/shm/pmemkv-ruby'
SIZE = 1024 * 1024 * 8

describe KVEngine do

  before do
    File.delete(PATH) if File.exist?(PATH)
    expect(File.exist?(PATH)).to be false
  end

  after do
    File.delete(PATH) if File.exist?(PATH)
    expect(File.exist?(PATH)).to be false
  end

  it 'creates instance' do
    size = 1024 * 1024 * 11
    kv = KVEngine.new(ENGINE, PATH, size)
    expect(kv.closed?).to be false
    kv.close
    expect(kv.closed?).to be true
  end

  it 'creates instance from existing pool' do
    size = 1024 * 1024 * 13
    kv = KVEngine.new(ENGINE, PATH, size)
    kv.close
    expect(kv.closed?).to be true
    kv = KVEngine.new(ENGINE, PATH, 0)
    expect(kv.closed?).to be false
    kv.close
    expect(kv.closed?).to be true
  end

  it 'closes instance multiple times' do
    size = 1024 * 1024 * 15
    kv = KVEngine.new(ENGINE, PATH, size)
    expect(kv.closed?).to be false
    kv.close
    expect(kv.closed?).to be true
    kv.close
    expect(kv.closed?).to be true
    kv.close
    expect(kv.closed?).to be true
  end

  it 'gets missing key' do
    kv = KVEngine.new(ENGINE, PATH)
    expect(kv.get('key1')).to be nil
    kv.close
  end

  it 'puts basic value' do
    kv = KVEngine.new(ENGINE, PATH)
    kv.put('key1', 'value1')
    expect(kv.get('key1')).to eql 'value1'
    kv.close
  end

  it 'puts binary key' do
    kv = KVEngine.new(ENGINE, PATH)
    kv.put("A\0B\0\0C", 'value1')
    expect(kv.get("A\0B\0\0C")).to eql 'value1'
    kv.close
  end

  it 'puts binary value' do
    kv = KVEngine.new(ENGINE, PATH)
    kv.put('key1', "A\0B\0\0C")
    expect(kv.get('key1')).to eql "A\0B\0\0C"
    kv.close
  end

  it 'puts complex value' do
    kv = KVEngine.new(ENGINE, PATH)
    val = 'one\ttwo or <p>three</p>\n {four}   and ^five'
    kv.put('key1', val)
    expect(kv.get('key1')).to eql val
    kv.close
  end

  it 'puts empty key' do
    kv = KVEngine.new(ENGINE, PATH)
    kv.put('', 'empty')
    kv.put(' ', 'single-space')
    kv.put('\t\t', 'two-tab')
    expect(kv.get('')).to eql 'empty'
    expect(kv.get(' ')).to eql 'single-space'
    expect(kv.get('\t\t')).to eql 'two-tab'
    kv.close
  end

  it 'puts empty value' do
    kv = KVEngine.new(ENGINE, PATH)
    kv.put('empty', '')
    kv.put('single-space', ' ')
    kv.put('two-tab', '\t\t')
    expect(kv.get('empty')).to eql ''
    expect(kv.get('single-space')).to eql ' '
    expect(kv.get('two-tab')).to eql '\t\t'
    kv.close
  end

  it 'puts multiple values' do
    kv = KVEngine.new(ENGINE, PATH)
    kv.put('key1', 'value1')
    kv.put('key2', 'value2')
    kv.put('key3', 'value3')
    expect(kv.get('key1')).to eql 'value1'
    expect(kv.get('key2')).to eql 'value2'
    expect(kv.get('key3')).to eql 'value3'
    kv.close
  end

  it 'puts overwriting existing value' do
    kv = KVEngine.new(ENGINE, PATH)
    kv.put('key1', 'value1')
    expect(kv.get('key1')).to eql 'value1'
    kv.put('key1', 'value123')
    expect(kv.get('key1')).to eql 'value123'
    kv.put('key1', 'asdf')
    expect(kv.get('key1')).to eql 'asdf'
    kv.close
  end

  it 'puts utf-8 key' do
    kv = KVEngine.new(ENGINE, PATH)
    val = 'to remember, note, record'
    kv.put('记', val)
    expect(kv.get('记')).to eql val
    kv.close
  end

  it 'puts utf-8 value' do
    kv = KVEngine.new(ENGINE, PATH)
    val = '记 means to remember, note, record'
    kv.put('key1', val)
    expect(kv.get('key1')).to eql val
    kv.close
  end

  it 'puts very large value' do
    # todo finish
  end

  it 'removes key and value' do
    kv = KVEngine.new(ENGINE, PATH)
    kv.put('key1', 'value1')
    expect(kv.get('key1')).to eql 'value1'
    kv.remove('key1')
    expect(kv.get('key1')).to be nil
    kv.close
  end

  it 'throws exception on create when engine is invalid' do
    kv = nil
    begin
      kv = KVEngine.new('nope.nope', PATH)
      expect(true).to be false
    rescue ArgumentError => e
      expect(e.message).to eql 'unable to open persistent pool'
    end
    expect(kv).to be nil
  end

  it 'throws exception on create when path is invalid' do
    kv = nil
    begin
      kv = KVEngine.new(ENGINE, '/tmp/123/234/345/456/567/678/nope.nope')
      expect(true).to be false
    rescue ArgumentError => e
      expect(e.message).to eql 'unable to open persistent pool'
    end
    expect(kv).to be nil
  end

  it 'throws exception on create with huge size' do
    kv = nil
    begin
      kv = KVEngine.new(ENGINE, PATH, 9223372036854775807) # 9.22 exabytes
      expect(true).to be false
    rescue ArgumentError => e
      expect(e.message).to eql 'unable to open persistent pool'
    end
    expect(kv).to be nil
  end

  it 'throws exception on create with tiny size' do
    kv = nil
    begin
      kv = KVEngine.new(ENGINE, PATH, SIZE - 1) # too small
      expect(true).to be false
    rescue ArgumentError => e
      expect(e.message).to eql 'unable to open persistent pool'
    end
    expect(kv).to be nil
  end

  it 'throws exception on put when out of space' do
    kv = KVEngine.new(ENGINE, PATH)
    begin
      100000.times do |i|
        istr = i.to_s
        kv.put(istr, istr)
      end
      expect(true).to be false
    rescue RuntimeError => e
      expect(e.message).to start_with 'unable to put key:'
    end
    kv.close
  end

  it 'uses blackhole engine' do
    kv = KVEngine.new('blackhole', PATH)
    expect(kv.get('key1')).to be nil
    kv.put('key1', 'value123')
    expect(kv.get('key1')).to be nil
    kv.remove('key1')
    expect(kv.get('key1')).to be nil
    kv.close
  end

  it 'uses module to publish types' do
    expect(KVEngine.class.equal?(Pmemkv::KVEngine.class)).to be true
  end

end
