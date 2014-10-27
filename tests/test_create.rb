require 'test/unit'
require_relative '../create_log.rb'
require 'time'

class TestCreate < Test::Unit::TestCase

    def test_num_lines
    	keywords = %w(ERROR Login LoggedOut)
    	filename = "./logs/log_test.txt"
    	generate_log(filename, keywords, 50, Time.now, 2, 5, 86400)

    	file = File.open(filename).readlines 
    	expected = file.size
    	assert_equal(expected, 50)
    end

end