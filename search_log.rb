#!/usr/bin/env ruby
#/ Usage: search_log.rb [options]
# 
# search_log.rb - command line script for analysis of log file on the 
# occurencies of predefined keywords.
# Uses 'gnuplot' library for graphical representation of analysis
#
# Author: Yevgeniya Kobrina
# Date: 27.10.2014
#

require 'optparse'
require 'time'
#$LOAD_PATH.unshift(File.expand_path('../lib/', __FILE__))
require 'gnuplot'

# Parsing arguments from command line
#
def parse_options

	options = {}

	# Defalut values
	options[:noon] = false
	options[:insensitive] = false
	options[:graph] = false
	options[:delta] = 86400
	options[:write] = false

	OptionParser.new do |opts|
		opts.banner = 'Usage: search_log.rb -l -k [-o] [-i] [-g] [-t] [-d] -h'

		opts.on('-l', '--log=file FILE', 'Specify the path to the log file',
				String) do |file|
			options[:file] = file
		end

		opts.on('-k', '--keywords=a,b,c KEYWORDS','Comma separated list of then keywords', Array) do |kw|
			options[:keywords] = kw
		end

		opts.on('-o', '--output_file[=outf]', 'Specify the name of the output file', String) do |outf|
			options[:output_file] = outf
		end
		
		opts.on('-i', '--insensitive', 'Make a search case-insensitive') do
			options[:insensitive] = true
		end
		
		opts.on('-s', '--start[=time]', 'Search will start from this time point. If not set, default is the first timestamp in the log. Format of time: "dd.mm.yy hh:mm:ss"', String) do |s|
			options[:start] = s
		end

		opts.on('-e', '--finish[=time]', 'Search will end at this time point. If not set, default is the last timestamp in the log. Format: "dd.mm.yy hh:mm:ss"', String) do |e|
			options[:finish] = e
		end

		opts.on('-n', '--noon', 'Set 00:00:00 as time for start and finish dates') do
			options[:noon] = true
		end

		opts.on('-g', '--graph', 'Make a histogram of keywords occurencies over time') do
			options[:graph] = true
		end

		opts.on('-d', '--delta[=dt]', Integer, 'Time interval for calculating histogram, sec. Defaults is 1 d') do |dt|
			options[:delta] = dt
		end

		opts.on('-w', '--write', 'Write intermidiate results to files') do
			options[:write] = true
		end		

		# Displays a help screen
		opts.on_tail( '-h', '--help', 'Display help' ) do
			puts opts
			exit
		end
	end.parse!


	# Abort if required arguments are missing
	[options[:file], options[:keywords]].each do |opt|
		if opt.nil?
			abort "Please, provide at least log file name AND list of keywords" 
		end
	end

	# If search is case insensitive then downcase all keywords
	if options[:insensitive] 
		options[:keywords] = options[:keywords].map(&:downcase) 
	end

	# If location and name of the ouput file is not set it is placed in the 
	#   same folder as log file with "_result" name ending
	if options[:oufile].nil?
		options[:output_file] = make_filename(options[:file], "only",
											 options[:keywords])
	end 

	# Parse time from the argument or nil if incorrect format
	begin
		start_parsed = Date._parse(options[:start]).values_at(:year, :mon, :mday, :hour, :min, :sec, :zone)
		options[:start] = Time.mktime(*start_parsed)
	rescue 
		puts "Start time hasn't been set up correctly. Using first log entry time instead"
		options[:start] = nil
	end
	
	# Parse time from the argument or nil if incorrect format
	begin
		finish_parsed = Date._parse(options[:finish]).values_at(:year, :mon, :mday, :hour, :min, :sec, :zone)
		options[:finish] = Time.mktime(*finish_parsed)
	rescue 
		puts "Finish time hasn't been set up correctly. Using last log entry time instead"
		options[:finish] = nil
	end

	return options
end


# Analysing occurencies of keywords in the log file by lines. 
# Writes all lines with keywords occurence to the output file.
# Finds and stores keywords list if found in a log entry
#
# 	Params:
# 	filename 	(Sring) Full path + name to the log file
# 	keywords 	(Array) Array of keywords
# 	start 		(Time) Time to begin from
#  	finish 		(Time) Time to finish at
#  	output_file	(String) Full path + name to the new log file
#  	
# 	Output:
# 	data 		(Hash) {timestamp => [keywords_found_here]} Stores
#  						timestamps where keywords found ans list of
# 						keywords there
#
def analyse_log(filename, keywords, start, finish, output_file) 
 
	# initialize a data structure, where key is the timestamp of the log entry 
	#   and value contains an array of keywords that are found in this entry
	data = Hash.new{|h, k| h[k] = []}
		# open a log file for reading
		File.open(filename) do |log|
			# create and open an output file
			File.open(output_file, 'w') do |out|
				# for every line in the log file search for the keywords
				log.each_line do |line|
					# parse timestamp of the log entry
					timestamp = Time.parse(line[0..line.index('|')-1].to_s)

					# do analysis only if current timestamp is in the time 
					# interval
					if (timestamp > start) && (timestamp < finish)

						word_found = false
						# if any keyword is found in the line, write the line
						# to file
						count = 0
						keywords.each do |w| 
							if count == 0
								includes = line.include?(w)  
								if includes
									count += 1 
									out.puts(line) 							
									word_found = true
								end
								elsif count == 1
								break
							end
						end

						# # search for particular keywords in the line and 
						# # update the data structure
						# if word_found  
						# 	keywords.each do |w|
						# 		if line.include?(w)
						# 			# if current line includes the keyword 
						# 			# update data hash with keyword
						# 			data[timestamp] << w;
						# 		end
						# 	end
						# end
					end
				end
			end
		end
	return data
end

# Calculating frequency of each keyword occurence over time. 
# Uses data structure obtained by the "analyse_log()".
# Time interval (histogram bin) is adjustable.
# Obtained data used for plotting a graph with plot_graph()
#
# 	Params:
# 	data 			(Hash) {timestamp => [keywords_found_here]} stores
#  							timestamps where keywords found ans list of
# 							keywords
# 	keywords 		(Array) Array of keywords
# 	start 			(Time) Time to begin from
#  	delta 			(Integer) Time interval (bins for histogram), in sec 
#  	
# 	Output:
# 	keyword_freq	(Hash) {keyword => {time_interval => numer_of_appearances}}
#  							stores number of appearance of a keyword in the
# 							time interval
#
def prepare_data(data, keywords, start, delta)
	# Initialize a hash where key is a keyword and value is a hash containing
	#   time interval and number of keyword appearances in this interval 
	keyword_freq = Hash.new{|h, k| h[k] = Hash.new(0)}

	# keywords analysed independently
	keywords.each do |word|
		# get the timestamps array only for the lines where the keyword was 
		# found
		time_array = data.select{|k, v| v.include?(word)}.keys
		if time_array.size == 0 
			keyword_freq[word][0]=0
		end

		# initialize second time point of the time interval
		delta = delta.to_i
		time_point = start + delta

			# for each timestamp perform its mapping to correct time interval
			#   and calculate histogram 
			time_array.each do |t|
				time_in = false

				while !time_in
					# if timestamp is in the interval 
					if t <= time_point
						keyword_freq[word][time_point] += 1
						time_in = true
					# move to the next interval
					else
						time_point += delta
						time_in = false
					end
				end
			end

	end
	return keyword_freq
end


# Plotting histogram for each keyword based on the 'data' structure
#   It uses Gnuplot data visualization tool which can be found from
#   https://github.com/rdp/ruby_gnuplot
# 	Graph show number of appearances of the keyword in the predefined time
# 	intervals. 
# 
# 	Params:
# 	data 		(Hash) {keyword => {time_interval => numer_of_appearances}}
# 						Produced by the method "prepare_data()"
# 	keywords 	(Array) Array of the keywords
#  	delta 		(Integer) time interval (bins for histogram), in sec 
#  	
# 	Output:
# 	'*.png' 	(File) Image file
#
def plot_graph (data, keywords, delta)

	keywords.each do |word|
		if data[word].keys[0] != 0
			Gnuplot.open do |gp|
				Gnuplot::Plot.new(gp) do |plot|
					# for each keyword create a separate graph 
					plot.terminal "png"
					plot.output "graphs/hist_" + word + ".png"
					plot.xlabel "Time"
					# get the frequency values for the keyword from the data hash
					yrange = data[word].values
					plot.ylabel "Frequency"
					plot.title "'" + word + "' in (" + 
								data[word].keys[0].strftime("%b %d %Y %H:%M:%S") + 
								" - " + data[word].keys[-1].strftime("%b %d %H:%M:%S") + 
								") with delta = " + (delta/60).to_s + " min"

					plot.data << Gnuplot::DataSet.new(yrange) do |ds|
						ds.with = "linespoints"
						ds.linewidth = 2
					end
				end
			end
		end
	end
end


# Checking existance of the log file. If file cannot be read, abort
# 	Params:
# 	filename		path + filename to the log file for analysis
#
def file_exists?(filename)
	if !File.exists?(filename) 
		abort "Unable to read file #{filename}"
	end
end

# Parsing and formatting time points of the interval 
# 
# 	Usage: [start, finish] = get_time_interval("logs/test_log.txt", 
#	Time.parse(30.10.2014 10:00:00), nil, false)
# 	Produce: [start, finish] = [2014-10-30 10:00:00,2014-12-26 17:05:10 +02:00]
#
# 	Params:
# 	filename 	(Sring) Full path + name to the log file
# 	start 		(Time or Nil) Time to begin from
#  	finish 		(Time or Nil) Time to finish at
# 	from_noon 	(Boolean) Start day from noon? 
#  	
# 	Output:
# 	start 		(Time) Formatted time to begin from
#  	finish 		(Time) Formatted time to finish at
#
def get_time_interval (filename, start, finish, from_noon)

	file = File.open(filename)
	# parse first timestamp in the log
	first_row = file.gets
	first_time = Time.parse(first_row[0..(first_row.index('|')-1)].to_s)

	# if not set the default value is the first timestamp in the log
	if start == nil
		start = first_time
	end
	
	# if not set the default value is the last timestamp in the log
	if finish == nil
		finish = Time.parse("31.12.3000 23:59:59")
	elsif
		finish < first_time
		abort "Last time is out of the log time interval"
	end

	# Start day from 00:00:00 if required
	if from_noon
		start = adjust_to_noon(start)
		finish = adjust_to_noon(finish)
	end
	return start, finish
end


# Changes time part of the data so that it is become 00:00:00 (noon) 
# 
# 	Usage: time = Time.parse("Oct 16 2014 12:00:05")
# 		   new_time = adjust_to_noon(time)
# 	Produce: new_time = 2014-10-16 00:00:00 +02:00
#
# 	Params:
# 	time 			(Time) Time object with at least year, month and day
#  	
# 	Output:
# 	new_time		(Time) New time object

#
def adjust_to_noon (time)
	new_time = Time.new(time.year, time.month, time.day) 
	return new_time
end


# Constructing filename for output file so that it is stored in the "/results" 
# 	folder. Filename will also include list of keywords used for analysis and
# 	short description.
#
# 	Usage: new_filename = make_filename("logs/test_log.txt", "output", 
#	["ERROR", "THIS"]) 
# 	Produce: new_filename = "logs/results/test_log_output_ERROR_THIS.txt"
#
# 	Params:
# 	filename 		(Sring) Full path + name to the log (initial) file
#	description		(String) Short clarification of what isin the file 
# 	keywords 		(Array) Array of keywords
#  	
# 	Output:
# 	new_filename	(Sring) Full path + name to the log (initial) file
#
def make_filename(filename, description, keywords)
	keywords = keywords.join("_")
	new_filename = File.dirname(filename) +  "/results/" + File.basename(filename).chomp(File.extname(filename)) + "_" + description + "_" + keywords + ".txt"	
	return new_filename
end

# Write data to the file and save it under filename. 
#
# 	Params:
# 	filename 		(Sring) Full path + name to the log (initial) file
#	data			(Any data) Whatever needs to be written 
#  	
# 	Output:
# 	'*.txt'			(File) Full path + name to the log (initial) file
#
def write_data(filename, data)
	File.open(filename, 'w').puts(data)
end


if $0 == __FILE__ 
	# Parse arguments from the command line
	options = parse_options
	# Check existance of file. If not found abort
	file_exists?(options[:file])
	# prepare start and finish times
	options[:start], options[:finish] = get_time_interval(options[:file],
		options[:start], options[:finish], options[:noon])

	# Run analysis and write lines to the output file
	data = analyse_log(options[:file], options[:keywords], options[:start], 
		options[:finish], options[:output_file])

	if data.size == 0
		puts "No log entries were found"
	else
		puts "Found " + data.size.to_s + " lines"
	end

	if options[:write] 
		filename = make_filename(options[:file], "data", options[:keywords])
		write_data(filename, data)
	end

	# If graphical representation needed
	if options[:graph] 

		# Calculate frequencies of keywords appearances throughout file 
		data_hist = prepare_data(data, options[:keywords], options[:start], 
			options[:delta])

		# Write data structures to the files if needed
		if options[:write] 
			filename = make_filename(options[:file], "freq", options[:keywords])
			write_data(filename, data_hist)
		end
		
		# Write plots to '*.png' image files 
		plot_graph(data_hist, options[:keywords], options[:delta])
	end

end 