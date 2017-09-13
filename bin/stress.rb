require '../lib/pmemkv/kv_engine'

class Stress

  kv = KVEngine.new('blackhole', '/dev/shm/stress', 1024 * 1024 * 1104)

  t1 = Time.now
  6012298.times do |i|
    str = i.to_s
    kv.put(str, "#{str}!")
  end
  puts "Put: #{Time.now - t1} sec"

end