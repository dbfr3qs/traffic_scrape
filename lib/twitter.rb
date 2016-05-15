require "twitter/version"
# script to scrape the NZTA WGTN twitter feed for rush hour ETA data 
# and store in sqlite3 database

module Twitter
 
	require 'rubygems'
	require 'oauth'
	require 'json'
	require 'eta'
	require 'sequel'
	require 'db'
	require 'optparse'

	options = {:scrapes => nil}
	Data = Db.new
	@etas = Array.new
	@auth = File.new("auth.json", "r")

	def Twitter.query_twitter(max_id) # get tweets
		baseurl = "https://api.twitter.com"
		path    = "/1.1/statuses/user_timeline.json"
		unless max_id == nil
			query   = URI.encode_www_form(
		    	"screen_name" => "nztawgtn",
		    	"count" => 3200,
		    	"max_id" => max_id,
			)
		else
			query   = URI.encode_www_form(
		    	"screen_name" => "nztawgtn",
		    	"count" => 3200,
			)
		end
		address = URI("#{baseurl}#{path}?#{query}")
		request = Net::HTTP::Get.new address.request_uri
		# Set up HTTP.
		http             = Net::HTTP.new address.host, address.port
		http.use_ssl     = true
		http.verify_mode = OpenSSL::SSL::VERIFY_PEER

		creds = JSON.parse(IO.read(@auth))
		consumer_key = OAuth::Consumer.new(
		    creds["ConsumerKey"],
		    creds["ConsumerSecret"])
		access_token = OAuth::Token.new(
		    creds["AccessToken"],
		    creds["AccessTokenSecret"])

		# Issue the request.
		request.oauth! http, consumer_key, access_token
		http.start
		response = http.request request
		if response.code == '200' then
	  		tweets = JSON.parse(response.body)
	  		return tweets
		end
	end
	
	def Twitter.process_eta(lines, time) 
		
		lines.drop(1).each do |line|
			if /Manor Park/.match(line)
				words = line.split()
				@etas << Eta.new(time, "Manor Park", words[2])
			else
				words = line.split()
				@etas << Eta.new(time, words[0], words[1])
			end
		end
	end

	def Twitter.process_tweet(tweet)
		if /[0-1]?[0-9]:[0-9]{2}(am)?(pm)?( ETAs)/.match(tweet["text"])
			lines = tweet["text"].split("\n")
			process_eta(lines, (Time.parse(tweet["created_at"]) + 12 * 60 * 60).to_s)
		end
	end
	
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

	# Parse and print the Tweet if the response code was 200
	unless options[:scrapes] == nil
		(1..options[:scrapes].to_i).each do 
			tweets = query_twitter(Data.getLastTweetId)
			puts tweets.count
			@etas.clear
			tweets.each do |tweet|
				process_tweet(tweet)
			end

			@etas.each do |eta|
				Data.add(eta)
			end

			# add last tweet id to database
			Data.addLastTweetId((Time.parse(tweets.last["created_at"]) + 12 * 60 * 60).to_s, tweets.last["id"])
			puts Data.getLastTweetId()
		end
	else
		tweets = query_twitter(Data.getLastTweetId)

		tweets.each do |tweet|
			process_tweet(tweet)
		end

		@etas.each do |eta|
			Data.add(eta)
		end

		# add last tweet id to database
		Data.addLastTweetId((Time.parse(tweets.last["created_at"]) + 12 * 60 * 60).to_s, tweets.last["id"])
		puts "Last tweet ID in scrape: #{Data.getLastTweetId()}"
	end
	
end
