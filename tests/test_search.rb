require 'test/unit'
require_relative '../search_log.rb'
require 'time'

class TestSearch < Test::Unit::TestCase
	# Test that search results are written to the output file
	# 1. File exists and 2. There is at least one line in it

	def setup
		@filename = "./logs/log_test.txt"
	    @output_file = "./logs/log_test_only_ERROR.txt"
	    @keywords = %w(ERROR)
	    @start = Time.now
	end
    def test_write 

    	analyse_log(@filename, @keywords, @start, Time.parse("31.12.3000"), @output_file)
    	assert_equal(true, File.exists?(@output_file))

    	file = File.open(@output_file).readlines 
    	assert_equal(true, file.size > 0)
    end

    # Test that data structure is made correctly
    def test_format

	    data = analyse_log(@filename,@keywords, @start, Time.parse("31.12.3000"), @output_file)
    	data_hist = prepare_data(data, @keywords, @start, 3600)

    	assert_equal(true, data_hist.keys[0].class == String)
    	assert_equal(true, data_hist[@keywords[0]].keys[0].class == Time)
    	assert_equal(true, data_hist[@keywords[0]][0].class == Fixnum)
	end

end