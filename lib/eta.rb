class Eta
	
	attr_accessor :time
	attr_accessor :suburb
	attr_accessor :eta

	def initialize(time, suburb, eta)
		@time = time
		@suburb = suburb
		@eta = eta
	end

	def to_s
		puts @time
		puts @suburb
		puts @eta
	end
end
