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

require 'pmemkv/all'

ENGINE = 'vsmap'
CONFIG = "{\"path\":\"/dev/shm\"}"

describe KVEngine do

  it 'uses module to publish types' do
    expect(KVEngine.class.equal?(Pmemkv::KVEngine.class)).to be true
  end

  it 'uses blackhole engine' do
    kv = KVEngine.new('blackhole', CONFIG)
    expect(kv.count).to eql 0
    expect(kv.exists('key1')).to be false
    expect(kv.get('key1')).to be nil
    kv.put('key1', 'value123')
    expect(kv.count).to eql 0
    expect(kv.exists('key1')).to be false
    expect(kv.get('key1')).to be nil
    expect(kv.remove('key1')).to be true
    expect(kv.exists('key1')).to be false
    expect(kv.get('key1')).to be nil
    kv.stop
  end

  it 'starts engine' do
    kv = KVEngine.new(ENGINE, CONFIG)
    expect(kv).not_to be nil
    expect(kv.stopped?).to be false
    kv.stop
    expect(kv.stopped?).to be true
  end

  it 'stops engine multiple times' do
    kv = KVEngine.new(ENGINE, CONFIG)
    expect(kv.stopped?).to be false
    kv.stop
    expect(kv.stopped?).to be true
    kv.stop
    expect(kv.stopped?).to be true
    kv.stop
    expect(kv.stopped?).to be true
  end

  it 'gets missing key' do
    kv = KVEngine.new(ENGINE, CONFIG)
    expect(kv.exists('key1')).to be false
    expect(kv.get('key1')).to be nil
    kv.stop
  end

  it 'puts basic value' do
    kv = KVEngine.new(ENGINE, CONFIG)
    expect(kv.exists('key1')).to be false
    kv.put('key1', 'value1')
    expect(kv.exists('key1')).to be true
    expect(kv.get('key1')).to eql 'value1'
    kv.stop
  end

  it 'puts binary key' do
    kv = KVEngine.new(ENGINE, CONFIG)
    kv.put("A\0B\0\0C", 'value1')
    expect(kv.exists("A\0B\0\0C")).to be true
    expect(kv.get("A\0B\0\0C")).to eql 'value1'
    kv.stop
  end

  it 'puts binary value' do
    kv = KVEngine.new(ENGINE, CONFIG)
    kv.put('key1', "A\0B\0\0C")
    expect(kv.get('key1')).to eql "A\0B\0\0C"
    kv.stop
  end

  it 'puts complex value' do
    kv = KVEngine.new(ENGINE, CONFIG)
    val = 'one\ttwo or <p>three</p>\n {four}   and ^five'
    kv.put('key1', val)
    expect(kv.get('key1')).to eql val
    kv.stop
  end

  it 'puts empty key' do
    kv = KVEngine.new(ENGINE, CONFIG)
    kv.put('', 'empty')
    kv.put(' ', 'single-space')
    kv.put('\t\t', 'two-tab')
    expect(kv.exists('')).to be true
    expect(kv.get('')).to eql 'empty'
    expect(kv.exists(' ')).to be true
    expect(kv.get(' ')).to eql 'single-space'
    expect(kv.exists('\t\t')).to be true
    expect(kv.get('\t\t')).to eql 'two-tab'
    kv.stop
  end

  it 'puts empty value' do
    kv = KVEngine.new(ENGINE, CONFIG)
    kv.put('empty', '')
    kv.put('single-space', ' ')
    kv.put('two-tab', '\t\t')
    expect(kv.get('empty')).to eql ''
    expect(kv.get('single-space')).to eql ' '
    expect(kv.get('two-tab')).to eql '\t\t'
    kv.stop
  end

  it 'puts multiple values' do
    kv = KVEngine.new(ENGINE, CONFIG)
    kv.put('key1', 'value1')
    kv.put('key2', 'value2')
    kv.put('key3', 'value3')
    expect(kv.exists('key1')).to be true
    expect(kv.get('key1')).to eql 'value1'
    expect(kv.exists('key2')).to be true
    expect(kv.get('key2')).to eql 'value2'
    expect(kv.exists('key3')).to be true
    expect(kv.get('key3')).to eql 'value3'
    kv.stop
  end

  it 'puts overwriting existing value' do
    kv = KVEngine.new(ENGINE, CONFIG)
    kv.put('key1', 'value1')
    expect(kv.get('key1')).to eql 'value1'
    kv.put('key1', 'value123')
    expect(kv.get('key1')).to eql 'value123'
    kv.put('key1', 'asdf')
    expect(kv.get('key1')).to eql 'asdf'
    kv.stop
  end

  it 'puts utf-8 key' do
    kv = KVEngine.new(ENGINE, CONFIG)
    val = 'to remember, note, record'
    kv.put('记', val)
    expect(kv.exists('记')).to be true
    expect(kv.get('记')).to eql val
    kv.stop
  end

  it 'puts utf-8 value' do
    kv = KVEngine.new(ENGINE, CONFIG)
    val = '记 means to remember, note, record'
    kv.put('key1', val)
    expect(kv.get_string('key1')).to eql val
    kv.stop
  end

  it 'removes key and value' do
    kv = KVEngine.new(ENGINE, CONFIG)
    kv.put('key1', 'value1')
    expect(kv.exists('key1')).to be true
    expect(kv.get('key1')).to eql 'value1'
    expect(kv.remove('key1')).to be true
    expect(kv.remove('key1')).to be false
    expect(kv.exists('key1')).to be false
    expect(kv.get('key1')).to be nil
    kv.stop
  end

  it 'throws exception on start when config is empty' do
    kv = nil
    begin
      kv = KVEngine.new(ENGINE, '{}')
      expect(true).to be false
    rescue ArgumentError => e
      expect(e.message).to eql 'Config does not include valid path string'
    end
    expect(kv).to be nil
  end

  it 'throws exception on start when config is malformed' do
    kv = nil
    begin
      kv = KVEngine.new(ENGINE, '{')
      expect(true).to be false
    rescue ArgumentError => e
      expect(e.message).to eql 'Config could not be parsed as JSON'
    end
    expect(kv).to be nil
  end

  it 'throws exception on start when engine is invalid' do
    kv = nil
    begin
      kv = KVEngine.new('nope.nope', CONFIG)
      expect(true).to be false
    rescue ArgumentError => e
      expect(e.message).to eql 'Unknown engine name'
    end
    expect(kv).to be nil
  end

  it 'throws exception on start when path is invalid' do
    kv = nil
    begin
      kv = KVEngine.new(ENGINE, "{\"path\":\"/tmp/123/234/345/456/567/678/nope.nope\"}")
      expect(true).to be false
    rescue ArgumentError => e
      expect(e.message).to eql 'Config path is not an existing directory'
    end
    expect(kv).to be nil
  end

  it 'throws exception on start when path is wrong type' do
    kv = nil
    begin
      kv = KVEngine.new(ENGINE, '{"path":1234}')
      expect(true).to be false
    rescue ArgumentError => e
      expect(e.message).to eql 'Config does not include valid path string'
    end
    expect(kv).to be nil
  end

  it 'uses all test' do
    kv = KVEngine.new(ENGINE, CONFIG)
    kv.put('1', 'one')
    kv.put('2', 'two')

    x = ''
    kv.all {|k| x += "<#{k}>,"}
    expect(x).to eql '<1>,<2>,'

    kv.put('记!', 'RR')
    x = ''
    kv.all_strings {|k| x += "<#{k}>,"}
    expect(x).to eql '<1>,<2>,<记!>,'

    kv.stop
  end

  it 'uses all above test' do
    kv = KVEngine.new(ENGINE, CONFIG)
    kv.put('A', '1')
    kv.put('AB', '2')
    kv.put('AC', '3')
    kv.put('B', '4')
    kv.put('BB', '5')
    kv.put('BC', '6')

    x = ''
    kv.all_above('B') {|k| x += "#{k},"}
    expect(x).to eql 'BB,BC,'

    kv.put('记!', 'RR')
    x = ''
    kv.all_strings_above('') {|k| x += "#{k},"}
    expect(x).to eql 'A,AB,AC,B,BB,BC,记!,'

    kv.stop
  end

  it 'uses all below test' do
    kv = KVEngine.new(ENGINE, CONFIG)
    kv.put('A', '1')
    kv.put('AB', '2')
    kv.put('AC', '3')
    kv.put('B', '4')
    kv.put('BB', '5')
    kv.put('BC', '6')

    x = ''
    kv.all_below('B') {|k| x += "#{k},"}
    expect(x).to eql 'A,AB,AC,'

    kv.put('记!', 'RR')
    x = ''
    kv.all_strings_below("\uFFFF") {|k| x += "#{k},"}
    expect(x).to eql 'A,AB,AC,B,BB,BC,记!,'

    kv.stop
  end

  it 'uses all between test' do
    kv = KVEngine.new(ENGINE, CONFIG)
    kv.put('A', '1')
    kv.put('AB', '2')
    kv.put('AC', '3')
    kv.put('B', '4')
    kv.put('BB', '5')
    kv.put('BC', '6')

    x = ''
    kv.all_between('A', 'B') {|k| x += "#{k},"}
    expect(x).to eql 'AB,AC,'

    kv.put('记!', 'RR')
    x = ''
    kv.all_strings_between('B', "\xFF") {|k| x += "#{k},"}
    expect(x).to eql 'BB,BC,记!,'

    x = ''
    kv.all_between('', '') {|k| x += "#{k},"}
    kv.all_between('A', 'A') {|k| x += "#{k},"}
    kv.all_between('B', 'A') {|k| x += "#{k},"}
    expect(x).to eql ''

    kv.stop
  end

  it 'uses count test' do
    kv = KVEngine.new(ENGINE, CONFIG)
    kv.put('A', '1')
    kv.put('AB', '2')
    kv.put('AC', '3')
    kv.put('B', '4')
    kv.put('BB', '5')
    kv.put('BC', '6')
    kv.put('BD', '7')
    expect(kv.count).to eql 7

    expect(kv.count_above('')).to eql 7
    expect(kv.count_above('A')).to eql 6
    expect(kv.count_above('B')).to eql 3
    expect(kv.count_above('BC')).to eql 1
    expect(kv.count_above('BD')).to eql 0
    expect(kv.count_above('Z')).to eql 0

    expect(kv.count_below('')).to eql 0
    expect(kv.count_below('A')).to eql 0
    expect(kv.count_below('B')).to eql 3
    expect(kv.count_below('BD')).to eql 6
    expect(kv.count_below('ZZZZZ')).to eql 7

    expect(kv.count_between('', 'ZZZZ')).to eql 7
    expect(kv.count_between('', 'A')).to eql 0
    expect(kv.count_between('', 'B')).to eql 3
    expect(kv.count_between('A', 'B')).to eql 2
    expect(kv.count_between('B', 'ZZZZ')).to eql 3

    expect(kv.count_between('', '')).to eql 0
    expect(kv.count_between('A', 'A')).to eql 0
    expect(kv.count_between('AC', 'A')).to eql 0
    expect(kv.count_between('B', 'A')).to eql 0
    expect(kv.count_between('BD', 'A')).to eql 0
    expect(kv.count_between('ZZZ', 'B')).to eql 0

    kv.stop
  end

  it 'uses each test' do
    kv = KVEngine.new(ENGINE, CONFIG)
    kv.put('1', 'one')
    kv.put('2', 'two')

    x = ''
    kv.each {|k, v| x += "<#{k}>,<#{v}>|"}
    expect(x).to eql '<1>,<one>|<2>,<two>|'

    kv.put('记!', 'RR')
    x = ''
    kv.each_string {|k, v| x += "<#{k}>,<#{v}>|"}
    expect(x).to eql '<1>,<one>|<2>,<two>|<记!>,<RR>|'

    kv.stop
  end

  it 'uses each above test' do
    kv = KVEngine.new(ENGINE, CONFIG)
    kv.put('A', '1')
    kv.put('AB', '2')
    kv.put('AC', '3')
    kv.put('B', '4')
    kv.put('BB', '5')
    kv.put('BC', '6')

    x = ''
    kv.each_above('B') {|k, v| x += "#{k},#{v}|"}
    expect(x).to eql 'BB,5|BC,6|'

    kv.put('记!', 'RR')
    x = ''
    kv.each_string_above('') {|k, v| x += "#{k},#{v}|"}
    expect(x).to eql 'A,1|AB,2|AC,3|B,4|BB,5|BC,6|记!,RR|'

    kv.stop
  end

  it 'uses each below test' do
    kv = KVEngine.new(ENGINE, CONFIG)
    kv.put('A', '1')
    kv.put('AB', '2')
    kv.put('AC', '3')
    kv.put('B', '4')
    kv.put('BB', '5')
    kv.put('BC', '6')

    x = ''
    kv.each_below('AC') {|k, v| x += "#{k},#{v}|"}
    expect(x).to eql 'A,1|AB,2|'

    kv.put('记!', 'RR')
    x = ''
    kv.each_string_below("\xFF") {|k, v| x += "#{k},#{v}|"}
    expect(x).to eql 'A,1|AB,2|AC,3|B,4|BB,5|BC,6|记!,RR|'

    kv.stop
  end

  it 'uses each between test' do
    kv = KVEngine.new(ENGINE, CONFIG)
    kv.put('A', '1')
    kv.put('AB', '2')
    kv.put('AC', '3')
    kv.put('B', '4')
    kv.put('BB', '5')
    kv.put('BC', '6')

    x = ''
    kv.each_between('A', 'B') {|k, v| x += "#{k},#{v}|"}
    expect(x).to eql 'AB,2|AC,3|'

    kv.put('记!', 'RR')
    x = ''
    kv.each_string_between('B', "\xFF") {|k, v| x += "#{k},#{v}|"}
    expect(x).to eql 'BB,5|BC,6|记!,RR|'

    x = ''
    kv.each_between('', '') {|k, v| x += "#{k},#{v}|"}
    kv.each_between('A', 'A') {|k, v| x += "#{k},#{v}|"}
    kv.each_between('B', 'A') {|k, v| x += "#{k},#{v}|"}
    expect(x).to eql ''

    kv.stop
  end

end
