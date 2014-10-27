#!/usr/bin/env ruby
#
# create_log.rb - command line script generating of a simple log file 
# for testing purposes. Lines are in the form of: 
# "Oct 14 2014 17:02:15|User 124935 LoggedOut". 
#
# Author: Yevgeniya Kobrina
# Date: 27.10.2014
#

require 'optparse'
require 'time'

# Parsing arguments from the command line
#
def parse_options

	options = {}
	# Defalut values
	options[:lines] = 10000
	options[:minwords] = 2
	options[:maxwords] = 5
	options[:delta] = 600

	OptionParser.new do |opts|
		opts.banner = 'Usage: create_log.rb -f -k -n [-s] [-l] [-d] [-h]'

		opts.on('-f', '--file=file FILE', 'Path + name of the output file', String) do |file|
			options[:file] = file
		end

		opts.on('-k', '--keywords=a,b,c KEYWORDS','Comma separated list of the keywords to be', 
			 	'included to the log', Array) do |kw|
			options[:keywords] = kw
		end

		opts.on('-n', '--lines=n LINES', 'Number of lines in the log', Integer) do |n|
			options[:lines] = n
		end

		opts.on('-t', '--time[=t]', 'First time point of the log, default is a current time', String) do |t|
			options[:time] = t
		end
			
		opts.on('-s', '--minwords[=num]', 'Minimum number of words in one log entry, default 2', Integer) do |s|
			options[:minwords] = s
		end
		
		opts.on('-l', '--maxwords[=num]', 'Maximum number of words in one log entry, default 5', Integer) do |l|
			options[:maxwords] = l
		end

		opts.on('-d', '--delta[=num]', 'Maximum time interval between log entries, in seconds, >600. Default is 10 min.', Integer) do |d|
			options[:delta] = d
		end

		# Displays a help screen
		opts.on_tail( '-h', '--help', 'Display help' ) do
			puts opts
			exit
		end
	end.parse!

	# Abort if required arguments are missing
	[options[:file], options[:keywords], options[:lines]].each do |opt|
		if opt.nil?
			abort "Please, provide at least log file name AND list of keywords" 
		end
	end

	# Parse time from the argument or nil if incorrect format
	begin
		time = Date._parse(options[:time]).values_at(:year, :mon, :mday, :hour, :min, :sec, :zone)
		options[:time] = Time.mktime(*time)
	rescue 
		puts "Time hasn't been set up correctly. Using current time instead"
		options[:time] = Time.now
	end

	return options
end

# Generate a log file of specified length (num_lines). Each line has the following view:
#   Timestamp|Description , example: Oct 14 2014 17:02:15|User 124935 LoggedOut
#   Timestamps begin from the defined value and incremented by delta 
#   Description contains random english words and includes zero or several keywords. 
#   Minimum and maximum number of words in one description can be set.
#   Generated log is written to the output_file
# 	Params:
#  	output_file		(String) Full path + name to the new log file
# 	keywords 		(Array) Array of keywords
#  	timestamp 		(Time) First time point of the log, e.g. Time.now
# 	num_lines		(Integer) Number of lines in the log
# 	min_words		(Integer) Minimum number of words in the log entry description
# 	max_words		(Integer) Maximum number of words in the log entry description
#  	delta			(Integer) Maximum time interval between consecutive entries, in sec 
#
def generate_log(output_file, keywords, num_lines, timestamp, min_words, max_words, delta)

	# open file for writing
	target = File.open(output_file, "w")

	# read dictionary file
	dictionary = open("dict/words.txt").readlines

	# generate a log with num lines in it
	num_lines.times do
		# first, append timestamp to the line
		line = timestamp.strftime("%b %d %Y %H:%M:%S") + "|"
		# increment a timestamp by the random number of seconds (max 10 min)
		timestamp += rand(10...delta)
		# initialize array of words
		words = []
		number_words = 0
		# maximum number of words in line 
		while number_words < rand(min_words...max_words)
			# randomly add a keyword 
			if rand(3)==0
				# include a random keyword 
				if rand(4)==0
					# the first keyword will appear more frequently
					words<<keywords[0].strip
				else
					words<<keywords[rand(1..keywords.size-1)].strip
					number_words += 1
				end
			end
			# add a random word from the dictionary 
			words<<dictionary[rand(dictionary.size)].chomp
			number_words += 1
		end
		# construct a line from words 
		line += words.join(" ")
		target.puts(line)
		end
	target.close
end


if $0 == __FILE__ 
	# parse arguments from the command line
	options = parse_options
	# analyse the appearance of the keywords in the log file and print
	#   lines where they found to the output file
	generate_log(options[:file], options[:keywords],  options[:lines], options[:time], options[:minwords], options[:maxwords], options[:delta])
	puts "Succesfully created file '" + options[:file] + "' with " + options[:lines].to_s + " lines "
end
