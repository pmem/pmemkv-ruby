require '../lib/pmemkv/kv_engine'

def test_engine(engine, count)
  puts "\nTesting #{engine} engine..."
  kv = KVEngine.new(engine, '/dev/shm/pmemkv', 1024 * 1024 * 1104)

  puts "Putting #{count} sequential values"
  t1 = Time.now
  count.times do |i|
    str = i.to_s
    kv.put(str, "#{str}!")
  end
  puts "   in #{Time.now - t1} sec"

  puts "Getting #{count} sequential values"
  t1 = Time.now
  failures = 0
  count.times do |i|
    str = i.to_s
    failures += 1 if kv.get(str).nil?
  end
  puts "   in #{Time.now - t1} sec, failures=#{failures}"
end

count = 6012298
test_engine('kvtree', count)
test_engine('blackhole', count)
puts "\nFinished!\n\n"