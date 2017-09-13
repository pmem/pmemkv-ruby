require '../lib/pmemkv/kv_engine'

class Stress

  kv = KVEngine.new('blackhole', '/dev/shm/stress', 1024 * 1024 * 1104)

  # kv.put('key1', 'value1')
  # puts "!!!!!!!!!!!!!!!!!!>#{kv.get('key1')}<"
  # # puts "!!!!!!!!!!!!!!!!!!>#{kv.get2('key1')}<"

  t1 = Time.now
  6012298.times do |i|
    str = i.to_s
    kv.put(str, "#{str}!")
  end
  puts "Put: #{Time.now - t1} sec"

  # t1 = Time.now
  # 6012298.times do |i|
  #   str = i.to_s
  #   kv.get(str)
  # end
  # puts "Get: #{Time.now - t1} sec"

  #
  # t1 = Time.now
  # 6012298.times do |i|
  #   str = i.to_s
  #   kv.put2(str, "#{str}!")
  # end
  # puts "Put2: #{Time.now - t1} sec"

  # t1 = Time.now
  # 6012298.times do |i|
  #   str = i.to_s
  #   kv.put(str, "#{str}!")
  # end
  # puts "Put3: #{Time.now - t1} sec"

  # t1 = Time.now
  # 6012298.times do |i|
  #   str = i.to_s
  #   kv.put4(str, "#{str}!")
  # end
  # puts "Put4: #{Time.now - t1} sec"

  # t1 = Time.now
  # 6012298.times do |i|
  #   str = i.to_s
  #   kv.get(str)
  # end
  # puts "Get: #{Time.now - t1} sec"
  #
  # puts "123456 is #{kv.get('123456')}"

end