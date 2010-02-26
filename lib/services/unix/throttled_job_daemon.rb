#!/usr/bin/ruby
$log_path = File.join(File.dirname(__FILE__), '..', '..', '..', 'log', 'throttled_job_daemon.log')
ENV["RAILS_ENV"] = ARGV[0] unless ARGV.empty?

require(File.join(File.dirname(__FILE__), '..', '..', '..', 'config', 'boot'))
require(File.join(RAILS_ROOT, 'config', 'environment'))

ThrottledService.new.start