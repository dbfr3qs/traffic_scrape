require 'twitter'

options = {:scrapes => nil}

parser = OptionParser.new do |opts|
	opts.banner = "Usage: twitter.rb [options]"
	opts.on("-s s", "--scrapes=s", "number of scrapes to perform") do |scrapes|
		options[:scrapes] = scrapes
	end 
	opts.on("-h", "--help", "Displays help") do
		puts opts
		exit
	end
end

parser.parse! # parse command line options

unless options[:scrapes] == nil
	(1..options[:scrapes].to_i).each do 
		Twitter.scrape_tweets()
	end
	puts "Last tweet ID in scrape: #{Twitter::Data.getLastTweetId()}"
else
	Twitter.scrape_tweets()	
	puts "Last tweet ID in scrape: #{Twitter::Data.getLastTweetId()}"
end
