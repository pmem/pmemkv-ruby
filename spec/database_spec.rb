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
CONFIG = "{\"path\":\"/dev/shm\",\"size\":1073741824}"

describe Database do

  it 'uses module to publish types' do
    expect(Database.class.equal?(Pmemkv::Database.class)).to be true
  end

  it 'uses blackhole engine' do
    db = Database.new('blackhole', CONFIG)
    expect(db.count_all).to eql 0
    expect(db.exists('key1')).to be false
    expect(db.get('key1')).to be nil
    db.put('key1', 'value123')
    expect(db.count_all).to eql 0
    expect(db.exists('key1')).to be false
    expect(db.get('key1')).to be nil
    expect(db.remove('key1')).to be true
    expect(db.exists('key1')).to be false
    expect(db.get('key1')).to be nil
    db.stop
  end

  it 'starts engine' do
    db = Database.new(ENGINE, CONFIG)
    expect(db).not_to be nil
    expect(db.stopped?).to be false
    db.stop
    expect(db.stopped?).to be true
  end

  it 'stops engine multiple times' do
    db = Database.new(ENGINE, CONFIG)
    expect(db.stopped?).to be false
    db.stop
    expect(db.stopped?).to be true
    db.stop
    expect(db.stopped?).to be true
    db.stop
    expect(db.stopped?).to be true
  end

  it 'gets missing key' do
    db = Database.new(ENGINE, CONFIG)
    expect(db.exists('key1')).to be false
    expect(db.get('key1')).to be nil
    db.stop
  end

  it 'puts basic value' do
    db = Database.new(ENGINE, CONFIG)
    expect(db.exists('key1')).to be false
    db.put('key1', 'value1')
    expect(db.exists('key1')).to be true
    expect(db.get('key1')).to eql 'value1'
    db.stop
  end

  it 'puts binary key' do
    db = Database.new(ENGINE, CONFIG)
    db.put("A\0B\0\0C", 'value1')
    expect(db.exists("A\0B\0\0C")).to be true
    expect(db.get("A\0B\0\0C")).to eql 'value1'
    db.stop
  end

  it 'puts binary value' do
    db = Database.new(ENGINE, CONFIG)
    db.put('key1', "A\0B\0\0C")
    expect(db.get('key1')).to eql "A\0B\0\0C"
    db.stop
  end

  it 'puts complex value' do
    db = Database.new(ENGINE, CONFIG)
    val = 'one\ttwo or <p>three</p>\n {four}   and ^five'
    db.put('key1', val)
    expect(db.get('key1')).to eql val
    db.stop
  end

  it 'puts empty key' do
    db = Database.new(ENGINE, CONFIG)
    db.put('', 'empty')
    db.put(' ', 'single-space')
    db.put('\t\t', 'two-tab')
    expect(db.exists('')).to be true
    expect(db.get('')).to eql 'empty'
    expect(db.exists(' ')).to be true
    expect(db.get(' ')).to eql 'single-space'
    expect(db.exists('\t\t')).to be true
    expect(db.get('\t\t')).to eql 'two-tab'
    db.stop
  end

  it 'puts empty value' do
    db = Database.new(ENGINE, CONFIG)
    db.put('empty', '')
    db.put('single-space', ' ')
    db.put('two-tab', '\t\t')
    expect(db.get('empty')).to eql ''
    expect(db.get('single-space')).to eql ' '
    expect(db.get('two-tab')).to eql '\t\t'
    db.stop
  end

  it 'puts multiple values' do
    db = Database.new(ENGINE, CONFIG)
    db.put('key1', 'value1')
    db.put('key2', 'value2')
    db.put('key3', 'value3')
    expect(db.exists('key1')).to be true
    expect(db.get('key1')).to eql 'value1'
    expect(db.exists('key2')).to be true
    expect(db.get('key2')).to eql 'value2'
    expect(db.exists('key3')).to be true
    expect(db.get('key3')).to eql 'value3'
    db.stop
  end

  it 'puts overwriting existing value' do
    db = Database.new(ENGINE, CONFIG)
    db.put('key1', 'value1')
    expect(db.get('key1')).to eql 'value1'
    db.put('key1', 'value123')
    expect(db.get('key1')).to eql 'value123'
    db.put('key1', 'asdf')
    expect(db.get('key1')).to eql 'asdf'
    db.stop
  end

  it 'puts utf-8 key' do
    db = Database.new(ENGINE, CONFIG)
    val = 'to remember, note, record'
    db.put('记', val)
    expect(db.exists('记')).to be true
    expect(db.get('记')).to eql val
    db.stop
  end

  it 'puts utf-8 value' do
    db = Database.new(ENGINE, CONFIG)
    val = '记 means to remember, note, record'
    db.put('key1', val)
    expect(db.get_string('key1')).to eql val
    db.stop
  end

  it 'removes key and value' do
    db = Database.new(ENGINE, CONFIG)
    db.put('key1', 'value1')
    expect(db.exists('key1')).to be true
    expect(db.get('key1')).to eql 'value1'
    expect(db.remove('key1')).to be true
    expect(db.remove('key1')).to be false
    expect(db.exists('key1')).to be false
    expect(db.get('key1')).to be nil
    db.stop
  end

  it 'throws exception on start when config is empty' do
    db = nil
    begin
      db = Database.new(ENGINE, '{}')
      expect(true).to be false
    rescue ArgumentError => e
      # XXX The expected error message should be changed to
      # 'JSON does not contain a valid path string'
      # when pmemkv_errmsg() is implemented.
      # There is no way to retrieve this error message now.
      expect(e.message).to eql 'pmemkv_open failed'
    end
    expect(db).to be nil
  end

  it 'throws exception on start when config is malformed' do
    db = nil
    begin
      db = Database.new(ENGINE, '{')
      expect(true).to be false
    rescue ArgumentError => e
      expect(e.message).to eql 'Creating a pmemkv config from JSON string failed'
    end
    expect(db).to be nil
  end

  it 'throws exception on start when engine is invalid' do
    db = nil
    begin
      db = Database.new('nope.nope', CONFIG)
      expect(true).to be false
    rescue ArgumentError => e
      # XXX The expected error message should be changed to
      # 'Unknown engine name'
      # when pmemkv_errmsg() is implemented.
      # There is no way to retrieve this error message now.
      expect(e.message).to eql 'pmemkv_open failed'
    end
    expect(db).to be nil
  end

  it 'throws exception on start when path is invalid' do
    db = nil
    begin
      db = Database.new(ENGINE, "{\"path\":\"/tmp/123/234/345/456/567/678/nope.nope\"}")
      expect(true).to be false
    rescue ArgumentError => e
      # XXX The expected error message should be changed to
      # 'Config path is not an existing directory'
      # when pmemkv_errmsg() is implemented.
      # There is no way to retrieve this error message now.
      expect(e.message).to eql 'pmemkv_open failed'
    end
    expect(db).to be nil
  end

  it 'throws exception on start when path is wrong type' do
    db = nil
    begin
      db = Database.new(ENGINE, '{"path":1234}')
      expect(true).to be false
    rescue ArgumentError => e
      expect(e.message).to eql 'Creating a pmemkv config from JSON string failed'
    end
    expect(db).to be nil
  end

  # it 'uses all test' do
  #   db = Database.new(ENGINE, CONFIG)
  #   db.put('1', 'one')
  #   db.put('2', 'two')

  #   x = ''
  #   db.all {|k| x += "<#{k}>,"}
  #   expect(x).to eql '<1>,<2>,'

  #   db.put('记!', 'RR')
  #   x = ''
  #   db.all_strings {|k| x += "<#{k}>,"}
  #   expect(x).to eql '<1>,<2>,<记!>,'

  #   db.stop
  # end

  # it 'uses all above test' do
  #   db = Database.new(ENGINE, CONFIG)
  #   db.put('A', '1')
  #   db.put('AB', '2')
  #   db.put('AC', '3')
  #   db.put('B', '4')
  #   db.put('BB', '5')
  #   db.put('BC', '6')

  #   x = ''
  #   db.all_above('B') {|k| x += "#{k},"}
  #   expect(x).to eql 'BB,BC,'

  #   db.put('记!', 'RR')
  #   x = ''
  #   db.all_strings_above('') {|k| x += "#{k},"}
  #   expect(x).to eql 'A,AB,AC,B,BB,BC,记!,'

  #   db.stop
  # end

  # it 'uses all below test' do
  #   db = Database.new(ENGINE, CONFIG)
  #   db.put('A', '1')
  #   db.put('AB', '2')
  #   db.put('AC', '3')
  #   db.put('B', '4')
  #   db.put('BB', '5')
  #   db.put('BC', '6')

  #   x = ''
  #   db.all_below('B') {|k| x += "#{k},"}
  #   expect(x).to eql 'A,AB,AC,'

  #   db.put('记!', 'RR')
  #   x = ''
  #   db.all_strings_below("\uFFFF") {|k| x += "#{k},"}
  #   expect(x).to eql 'A,AB,AC,B,BB,BC,记!,'

  #   db.stop
  # end

  # it 'uses all between test' do
  #   db = Database.new(ENGINE, CONFIG)
  #   db.put('A', '1')
  #   db.put('AB', '2')
  #   db.put('AC', '3')
  #   db.put('B', '4')
  #   db.put('BB', '5')
  #   db.put('BC', '6')

  #   x = ''
  #   db.all_between('A', 'B') {|k| x += "#{k},"}
  #   expect(x).to eql 'AB,AC,'

  #   db.put('记!', 'RR')
  #   x = ''
  #   db.all_strings_between('B', "\xFF") {|k| x += "#{k},"}
  #   expect(x).to eql 'BB,BC,记!,'

  #   x = ''
  #   db.all_between('', '') {|k| x += "#{k},"}
  #   db.all_between('A', 'A') {|k| x += "#{k},"}
  #   db.all_between('B', 'A') {|k| x += "#{k},"}
  #   expect(x).to eql ''

  #   db.stop
  # end

  it 'uses count all test' do
    db = Database.new(ENGINE, CONFIG)
    db.put('A', '1')
    db.put('AB', '2')
    db.put('AC', '3')
    db.put('B', '4')
    db.put('BB', '5')
    db.put('BC', '6')
    db.put('BD', '7')
    expect(db.count_all).to eql 7

    expect(db.count_above('')).to eql 7
    expect(db.count_above('A')).to eql 6
    expect(db.count_above('B')).to eql 3
    expect(db.count_above('BC')).to eql 1
    expect(db.count_above('BD')).to eql 0
    expect(db.count_above('Z')).to eql 0

    expect(db.count_below('')).to eql 0
    expect(db.count_below('A')).to eql 0
    expect(db.count_below('B')).to eql 3
    expect(db.count_below('BD')).to eql 6
    expect(db.count_below('ZZZZZ')).to eql 7

    expect(db.count_between('', 'ZZZZ')).to eql 7
    expect(db.count_between('', 'A')).to eql 0
    expect(db.count_between('', 'B')).to eql 3
    expect(db.count_between('A', 'B')).to eql 2
    expect(db.count_between('B', 'ZZZZ')).to eql 3

    expect(db.count_between('', '')).to eql 0
    expect(db.count_between('A', 'A')).to eql 0
    expect(db.count_between('AC', 'A')).to eql 0
    expect(db.count_between('B', 'A')).to eql 0
    expect(db.count_between('BD', 'A')).to eql 0
    expect(db.count_between('ZZZ', 'B')).to eql 0

    db.stop
  end

  it 'uses get all test' do
    db = Database.new(ENGINE, CONFIG)
    db.put('1', 'one')
    db.put('2', 'two')

    x = ''
    db.get_all {|k, v| x += "<#{k}>,<#{v}>|"}
    expect(x).to eql '<1>,<one>|<2>,<two>|'

    db.put('记!', 'RR')
    x = ''
    db.get_all_string {|k, v| x += "<#{k}>,<#{v}>|"}
    expect(x).to eql '<1>,<one>|<2>,<two>|<记!>,<RR>|'

    db.stop
  end

  it 'uses get above test' do
    db = Database.new(ENGINE, CONFIG)
    db.put('A', '1')
    db.put('AB', '2')
    db.put('AC', '3')
    db.put('B', '4')
    db.put('BB', '5')
    db.put('BC', '6')

    x = ''
    db.get_above('B') {|k, v| x += "#{k},#{v}|"}
    expect(x).to eql 'BB,5|BC,6|'

    db.put('记!', 'RR')
    x = ''
    db.get_string_above('') {|k, v| x += "#{k},#{v}|"}
    expect(x).to eql 'A,1|AB,2|AC,3|B,4|BB,5|BC,6|记!,RR|'

    db.stop
  end

  it 'uses get below test' do
    db = Database.new(ENGINE, CONFIG)
    db.put('A', '1')
    db.put('AB', '2')
    db.put('AC', '3')
    db.put('B', '4')
    db.put('BB', '5')
    db.put('BC', '6')

    x = ''
    db.get_below('AC') {|k, v| x += "#{k},#{v}|"}
    expect(x).to eql 'A,1|AB,2|'

    db.put('记!', 'RR')
    x = ''
    db.get_string_below("\xFF") {|k, v| x += "#{k},#{v}|"}
    expect(x).to eql 'A,1|AB,2|AC,3|B,4|BB,5|BC,6|记!,RR|'

    db.stop
  end

  it 'uses get between test' do
    db = Database.new(ENGINE, CONFIG)
    db.put('A', '1')
    db.put('AB', '2')
    db.put('AC', '3')
    db.put('B', '4')
    db.put('BB', '5')
    db.put('BC', '6')

    x = ''
    db.get_between('A', 'B') {|k, v| x += "#{k},#{v}|"}
    expect(x).to eql 'AB,2|AC,3|'

    db.put('记!', 'RR')
    x = ''
    db.get_string_between('B', "\xFF") {|k, v| x += "#{k},#{v}|"}
    expect(x).to eql 'BB,5|BC,6|记!,RR|'

    x = ''
    db.get_between('', '') {|k, v| x += "#{k},#{v}|"}
    db.get_between('A', 'A') {|k, v| x += "#{k},#{v}|"}
    db.get_between('B', 'A') {|k, v| x += "#{k},#{v}|"}
    expect(x).to eql ''

    db.stop
  end

  it 'uses get keys test' do
    db = Database.new(ENGINE, CONFIG)
    db.put('1', 'one')
    db.put('2', 'two')

    x = ''
    db.get_keys {|k| x += "<#{k}>,"}
    expect(x).to eql '<1>,<2>,'

    db.put('记!', 'RR')
    x = ''
    db.get_keys {|k| x += "<#{k}>,"}
    expect(x).to eql '<1>,<2>,<记!>,'

    db.stop
  end

end
