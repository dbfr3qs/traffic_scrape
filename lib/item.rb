class Item
	attr_accessor :day
	attr_accessor :month
	attr_accessor :year
	attr_accessor :hour
	attr_accessor :min
	attr_accessor :second

	attr_accessor :eta
	attr_accessor :suburb

	def initialize(day, month, year, hour, min, second, eta, suburb)
		@day = day
		@month = month
		@year = year
		@hour = hour
		@min = min
		@second	= second
		@eta = eta
		@suburb = suburb
	end
end	