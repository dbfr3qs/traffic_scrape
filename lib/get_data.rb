require 'twitter'

options = {:scrapes => nil, :forwards => nil}

parser = OptionParser.new do |opts|
	opts.banner = "Usage: twitter.rb [options]"
	opts.on("-b s", "--backwards=s", "perform scrape backwards") do |backwards|
		options[:scrapes] = backwards
	end 
	opts.on("-f s", "--forwards=s", "perform perform scrape forwards") do |forwards|
		options[:forwards] = forwards
	end
	opts.on("-h", "--help", "Displays help") do
		puts opts
		exit
	end
end

parser.parse! # parse command line options

#binding.pry

if options[:scrapes] != nil
	(1..options[:scrapes].to_i).each do 
		Twitter.scrape_tweets("backwards")
	end
	puts "Last tweet ID in scrape: #{Twitter::Data.getLastTweetId()}"

elsif options[:forwards] != nil
	(1..options[:forwards].to_i).each do 
		Twitter.scrape_tweets("forwards")
	end
	puts "Last tweet ID in scrape: #{Twitter::Data.getLastTweetId()}"
else
	Twitter.scrape_tweets()	
	puts "Last tweet ID in scrape: #{Twitter::Data.getLastTweetId()}"
end
