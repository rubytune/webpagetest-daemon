
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "web_page_test_daemon/create_job"
require "web_page_test_daemon/status_check_job"
require "web_page_test_daemon/blocking_job"
require "web_page_test_daemon/test_results_job"

require 'resque/tasks'
require 'resque/scheduler/tasks'
