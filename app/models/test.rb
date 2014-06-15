class Test
  def self.say_hi
    puts "Hi!!! #{Device.all.length}"
    Device.create
  end
end
