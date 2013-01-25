require 'rubygems'
require 'pp'
require '../lib/tablespoon.rb'

google_username = ENV['GOOGLE_USERNAME']
google_password = ENV['GOOGLE_PASSWORD']

puts "Looging into Google with " 
puts "#{google_username}"
puts "#{google_password}"

doc   = Tablespoon::Doc.new( "0ArhhvPZdTe-WdGpZQ3pEY1hDcEUxWmxwNnJEQ3g4aVE", 
                           :username => google_username, :password => google_password )

justices = doc.get_table 'Sheet1', :id_field => 'last-name'

justices.each do |r|
  r['full-name']       = r['full-name'].upcase 
  puts r['some_value'] = 'monkeys'
  sleep 2
end

