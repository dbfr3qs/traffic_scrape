require "twitter/version"

# scrape the NZTA WGTN twitter feed for rush hour ETA data 
# and store in sqlite3 database

module Twitter
 
	require 'rubygems'
	require 'oauth'
	require 'json'
	require 'eta'
	require 'sequel'
	require 'db'
	require 'crash'
	require 'optparse'
	require 'pry'

	Data = Db.new

	@@etas = Array.new
	@@crashes = Array.new
	@auth = File.new("auth.json", "r")

	def Twitter.query_twitter(max_id=nil, since_id=nil) # get tweets
		baseurl = "https://api.twitter.com"
		path    = "/1.1/statuses/user_timeline.json"
		if max_id != nil
			query   = URI.encode_www_form(
		    	"screen_name" => "nztawgtn",
		    	"max_id" => max_id,
		    	"count" => 200,
			)
		elsif since_id != nil
			query   = URI.encode_www_form(
		    	"screen_name" => "nztawgtn",
		    	"since_id" => since_id,
		    	"count" => 200,
			)
		else
			query   = URI.encode_www_form(
		    	"screen_name" => "nztawgtn",
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
				@@etas << Eta.new(time, "Manor Park", words[2])
			else
				words = line.split()	
				begin
					@@etas << Eta.new(time, words[0].include?('’') ? words[0].delete('’') : words[0], words[1])
				rescue
					puts "Reached maximum number of tweets allowed to scrape (3200)"
				end

			end
		end
	end

	def Twitter.process_crash(text, time)
		#t = Time.parse(time)
		begin
			match = /(SH1|SH2)/.match(text)
			highway = match[0]
			@@crashes << Crash.new(time, highway)
		rescue

		end	
	end

	def Twitter.process_tweet(tweet)
		lines = tweet["text"].split("\n") 
		if /[0-1]?[0-9]:[0-9]{2}(am)?(pm)?( ETAs)/.match(lines[0])
			# process for ETAs
			process_eta(lines, (Time.parse(tweet["created_at"]) + 12 * 60 * 60).to_s)
		end
		if /^((CRASH)|(Crash)|(crash)|(BREAKDOWN)|(Breakdown)|(breakdown)).*((SH2)|(SH1))/.match(tweet["text"])
			# keep track of crashes
			process_crash(tweet["text"], (Time.parse(tweet["created_at"]) + 12 * 60 * 60).to_s)
		end
	end

	def Twitter.scrape_tweets(direction)
		@@etas.clear
		@@crashes.clear
		if direction == "backwards"
			#binding.pry
			tweets = query_twitter(Data.getLastTweetId)
		elsif direction == "forwards"
			#binding.pry
			tweets = query_twitter(nil, Data.getFirstTweetId)
			#binding.pry
		else
			tweets = query_twitter()
		end

		puts tweets.count
		tweets.each do |tweet|
			process_tweet(tweet)
		end

		@@etas.each do |eta|
			Data.addEta(eta)
		end

		unless @@crashes.count == 0
			@@crashes.each do |crash|
				Data.addCrash(crash)
			end
		end 

		# add last tweet id to database
		#Data.addLastTweetId((Time.parse(tweets.last["created_at"]) + 12 * 60 * 60).to_s, tweets.last["id"])
		Data.addFirstAndLastTweetId((Time.now).to_s, tweets.first["id"], tweets.last["id"])
		puts Data.getLastTweetId()
	end
	
end
