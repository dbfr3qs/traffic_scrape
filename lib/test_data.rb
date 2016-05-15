require 'db'
require 'item'
require 'date'

data = Db.new
set = data.etas.where(:suburb => 'Porirua')

items = Array.new
# create array of items (eta objects)
set.each do |record|
	time = Time.parse(record[:time])
	
	item = Item.new(time.day, time.month, time.year, time.hour, time.min, time.sec, record[:eta], record[:suburb])
	items << item
end

# get the days in April that we have data for
days = items.select { |item| item.month == 5 }.map { |item| item.day.to_i }.uniq

averages = Array.new
data = Array.new

# calculate average eta for each day
days.each do |day|
	data = items.select { |item| item.day == day && item.month == 5 }.map { |record| record.eta.to_i } # get etas
	#times = data
	averages << (data.inject(0) { |sum, x| sum + x}) / data.count
end

def dayOfWeek(day) 
	theDate = Date.new(2016, 5, day)
	theDate.strftime('%a')
end

dayNames = Array.new
days.each do |day|
	dayNames << dayOfWeek(day) + " " + day.to_s 
end

count = 0
averages.each do |avg| 
	
	puts "#{dayNames[count]} #{avg}"
	count+=1
end

