require 'sqlite3'
require 'sequel'

class Db
	
	attr_accessor :DB 
	attr_accessor :etas

	def initialize()
		@DB = Sequel.connect('sqlite://data.db')
		@etas = @DB[:etas] # eta records
		@tweetids = @DB[:tweet_ids] # keep track of the max_id of the timeline
	end

	def addLastTweetId(time, tweet_id)
		begin
			@tweetids.insert(:time => time, :tweet_id => tweet_id)
		rescue Sequel::DatabaseError
			puts "Cannot find tweet_ids table so rebuilding from scratch"
			newTweetsIdTable(time, tweet_id)
		end
	end

	def getLastTweetId() # return the tweet id of the last tweet scraped
		begin
			record = @tweetids.order(:id).last
			record[:tweet_id]
		rescue Sequel::DatabaseError
			puts "Tweets ID database does not yet exist"
			return nil
		end
	end

	def newTweetsIdTable(time, tweet_id)
		@DB.create_table :tweet_ids do
			primary_key :id
			String :time
			Fixnum :tweet_id
		end

		@tweetids = @DB[:tweet_ids]
		@tweetids.insert(:time => time, :tweet_id => tweet_id)
	end

	def add(record)
		begin
			@etas.insert(:time => record.time, :suburb => record.suburb, :eta => record.eta)
		rescue Sequel::DatabaseError
			puts "Cannot find etas table so rebuilding from scratch"
			newEtasTable(record)
		end
	end

	def newEtasTable(record)
		@DB.create_table :etas do			
			primary_key :id
			String :time
			String :suburb
			String :eta	
		end
		
		@etas = @DB[:etas]
		@etas.insert(:time => record.time, :suburb => record.suburb, :eta => record.eta)
	end

	def deleteAll()
		@etas.delete
	end

	def getAll()
		@etas.all
	end

end