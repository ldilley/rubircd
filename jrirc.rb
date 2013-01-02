require_relative 'channel'
require_relative 'config'
require_relative 'log'
require_relative 'server'
require_relative 'user'

print("Parsing configuration file... ")
config = JRIRC::Config.new
puts("done.")
puts("Server name: #{config.server_name}\nTCP port: #{config.listen_port}")
# Proof of concept
puts("Simulating creation of a new user object...")
user = User.new("Joe", "joe", "localhost.dom", "something witty here")
puts("Current nick is: #{user.nick}")
user.change_nick("Jim")
puts("Nick changed to: #{user.nick}")
user.add_channel("#jibber")
user.add_channel("#jabber")
user.add_channel("#foo")
puts("\nCurrent channels:")
user.channels.each { |channel| puts(channel) }
user.remove_channel("#foo")
puts("\nChannels after removing #foo:")
user.channels.each { |channel| puts(channel) }
puts("\nCreating channel #test with a sample ban...")
channel = Channel.new("#test", "Jim")
channel.add_ban("Jim", "*!*jed@localhost.dom", "too smelly")
channel.remove_ban("*!*jed@localhost.dom")
puts("\nTesting logging functionality...")
log = Log.new
log.write_log("This is only a test.")
