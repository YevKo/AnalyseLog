
# CREATING AND SEARCHING LOG 

A tool for creating random text log and analysing it for lines that contain a keyword from a predefined list.
Number of lines, maximum number of words in the entry and maximum time interval between time stamps are parametrised.

Analysis results depend on the set of keywords and time interval passed. Output of analysis consists of new text file containing lines where keywords were found and figure plot showing frequency of keyword appearanceover time. It is possible to save intermediate results to .txt file.
Graphocal representation is made using Gnuplot gem. 
 
## Create log

Script generate a log file of specified length, log entries contain predefined keywords.
Each line of the following view: 
Timestamp|Description , example: Oct 14 2014 17:02:15|User 124935 LoggedOut
Timestamp begins from the defined value and incrementes by random number of seconds with some max value.

Each line populated by random words from the english dictionary and randomly includes zero or several keywords.Number of words in a line vary from defined minumum and maximum values. 

#### Notes: Each line does not necesarry contain a keyword and may contain several keywords. 	
			First keyword in the keywords array will appear more frequently than others. 


### Use 

	./create_log.rb [args]

#### Args
	
    -o, --file=file FILE             Path + name of the output file
    -k, --keywords=a,b,c KEYWORDS    Comma separated list of the keywords to be
                                     included to the log
    -n, --lines=n LINES              Number of lines in the log
    -t, --time[=t]                   First time point of the log, default is a current time
    -s, --minwords[=num]             Minimum number of words in one log entry, default 2
    -l, --maxwords[=num]             Maximum number of words in one log entry, default 5
    -d, --delta[=num]                Maximum time interval between log entries, in seconds, >600. Default is 10 min.

Path to the file --file, words array --keywords and number of lines --lines are mandatory arguments. 

If --time is not specified it is set to a current time. 
 
##### Note: Dictionary file is located in the /dict folder and is a Linux dictionary file. 

#### Examples of usage:

	./create_log.rb --file="logs/test_log.txt" --keywords="ERROR, LoggedOut, timedelay, login" --lines=1000 --delta=86400
	./create_log.rb --file="logs/test_log.txt" --keywords="ERROR, LoggedOut, timedelay, login" --delta=86400 --maxwords=10 --time="31.12.2013"

## Analyse log

Analysing occurencies of keywords in the log file. Reads each line, store keywords if found and writes this line to the output file. 
It is possible to save intermidiate results to the txt files.

#### Note: generated with 6 keywords test logs of 1 000, 10 000, 100 000 and 1 000 000 lines are located in the /logs folder

### Use 

	./search_log.rb [args]

#### Args
	
	-l, --log=file FILE              Specify the path to the log file
    -k, --keywords=a,b,c KEYWORDS    Comma separated list of then keywords
    -o, --output_file[=outf]         Specify the name of the output file
    -i, --insensitive                Make a search case-insensitive
    -s, --start[=time]               Search will start from this time point. If not set, default is the first 
    								 timestamp in the 
    								 log Format of time: "dd.mm.yy hh:mm:ss"
    -e, --finish[=time]              Search will end at this time point. If not set, default is the last 
    								 timestamp in the log. 
    								 Format: "dd.mm.yy hh:mm:ss"
    -n, --noon                       Set 00:00:00 as time for start and finish dates
    -g, --graph                      Make a histogram of keywords occurencies over time
    -d, --delta[=dt]                 Time interval for calculating histogram, sec. Defaults is 1 d
    -w, --write                      Write intermidiate results to files
    -h, --help                       Display help

Path to the file --log, words array --keywords are mandatory arguments. 
If ---start and --finish time points are not specified, they are taken from the corresponding log timestamps.

If -g flag is given, script calculates also frequency of each keyword appearance over time. Time interval is binned to smaller intervals of --delta length and number of keyword occurences in each interval is calculated.

#### Note: All output files are written to the /results folder.

#### Examples of usage:

	./search_log.rb --log="logs/test_log.txt" --keywords="ERROR, LoggedOut" --start="10.11.2014" -n
	./create_log.rb --log="logs/test_log.txt" --keywords="ERROR, LoggedOut, timedelay, login" -w

## Require

Required : 'rake' , 'gnuplot'

This tool require to install 'gnuplot' library (https://github.com/rdp/ruby_gnuplot) to create graph figures.

### How to install GnuPlot on Linux

------
	$ sudo apt-get install gnuplot
	$ sudo apt-get install gnuplot-x11
------


## Tests

To run tests from command line:

	$ rake test [--trace]
  
