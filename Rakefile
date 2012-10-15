require 'bundler/setup'
require 'sinatra/activerecord/rake'
require 'pry'
require './app'

Dir[File.join('lib', 'tasks', '**', '*.rake')].each do |file|
	import file
end

task :console do
	binding.pry
end