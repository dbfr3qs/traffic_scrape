class Crash

	attr_accessor :time
	attr_accessor :highway

	def initialize(time, highway)
		@time = time
		@highway = highway
	end

	def to_s
		puts @time
		puts @highway
	end
end