require 'sqlite3'
require 'sequel'

class Db
	
	attr_accessor :DB 
	attr_accessor :etas

	def initialize()
		@DB = Sequel.connect('sqlite://data.db')
		@etas = @DB[:etas] # eta records
		@tweetids = @DB[:tweet_ids] # keep track of the max_id of the timeline
		@crashes = @DB[:crashes]
	end

	def addLastTweetId(time, tweet_id)
		begin
			@tweetids.insert(:time => time, :tweet_id => tweet_id)
		rescue Sequel::DatabaseError
			puts "Cannot find tweet_ids table so rebuilding from scratch"
			newTweetsIdTable(time, tweet_id)
		end
	end

	def addFirstAndLastTweetId(time, first_id, last_id)
		begin
			@tweetids.insert(:time => time, :first_id => first_id, :last_id => last_id)
		rescue Sequel::DatabaseError
			puts "Cannot find tweet_ids table so rebuilding from scratch"
			newTweetsIdTable(time, first_id, last_id)
		end
	end

	def getLastTweetId() # return the tweet id of the last tweet scraped
		begin
			record = @tweetids.order(:id).last
			record[:last_id]
		rescue Sequel::DatabaseError
			puts "Tweets ID database does not yet exist"
			return nil
		end
	end

	def getFirstTweetId() 
		begin
			record = @tweetids.order(:first_id).last
			record[:first_id]
		rescue Sequel::DatabaseError
			puts "Tweets ID database does not yet exist"
			return nil
		end
	end

	def newTweetsIdTable(time, first_id, last_id)
		@DB.create_table :tweet_ids do
			primary_key :id
			String :time
			Fixnum :first_id
			Fixnum :last_id
		end

		@tweetids = @DB[:tweet_ids]
		@tweetids.insert(:time => time, :first_id => first_id, :last_id => last_id)
	end

	def addEta(record)
		begin
			@etas.insert(:time => record.time, :suburb => record.suburb, :eta => record.eta)
		rescue Sequel::DatabaseError
			puts "Cannot find etas table so rebuilding from scratch"
			newEtasTable(record)
		end
	end

	def newCrashTable(record) 
		@DB.create_table :crashes do
			primary_key :id
			String :time # 
			String :highway # SH1 or SH2
		end
		
		@crashes = @DB[:crashes]
		@crashes.insert(:time => record.time, :highway => record.highway)	
	end

	def addCrash(record)
		begin
			@crashes.insert(:time => record.time, :highway => record.highway)
		rescue Exception => e
			puts e.message
			puts "Cannot find crashes table so rebuilding from scratch"
			newCrashTable(record)
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

	def deleteAllEtas()
		@etas.delete
	end

	def getAllEtas()
		@etas.all
	end

end