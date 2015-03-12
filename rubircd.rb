# RubIRCd - An IRC server written in Ruby
# Copyright (C) 2013 Lloyd Dilley (see authors.txt for details) 
# http://www.rubircd.rocks/
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

if RUBY_VERSION < "1.9"
  puts("RubIRCd requires Ruby >=1.9!")
  exit!
end

require_relative 'channel'
require_relative 'eventmach'
require_relative 'log'
require_relative 'network'
require_relative 'options'
require_relative 'server'
require_relative 'user'

$LOAD_PATH << Dir.pwd() # needed so certain modules can get at classes in this top-level directory

puts(Server::VERSION)
print("Initializing logging... ")
Log.write(2, "Initializing logging...")
puts("done.")
Log.write(2, "Logging initialized.")
print("Parsing options file... ")
Options.parse(false)
puts("done.")
Log.write(2, "Options loaded.")
if Options.io_type.to_s == "em"
  EventMach.check_for_em()
end
Opers.parse(false)
if Options.debug_mode.to_s == "true"
  Thread.abort_on_exception = true
end
if Options.listen_host != nil && Options.ssl_port != nil
  puts("Server name: #{Options.server_name}\nAddress: #{Options.listen_host}\nTCP port: #{Options.listen_port}\nSSL port: #{Options.ssl_port}")
elsif Options.listen_host != nil && Options.ssl_port == nil
  puts("Server name: #{Options.server_name}\nAddress: #{Options.listen_host}\nTCP port: #{Options.listen_port}")
elsif Options.listen_host == nil && Options.ssl_port != nil
  puts("Server name: #{Options.server_name}\nTCP port: #{Options.listen_port}\nSSL port: #{Options.ssl_port}")
else
  puts("Server name: #{Options.server_name}\nTCP port: #{Options.listen_port}")
end
# ToDo: Add if check to determine if SSL is enabled and print port # if so
print("Reading MotD... ")
Server.read_motd(false)
puts("done.")
Log.write(2, "MotD loaded.")
print("Registering commands... ")
Command.register_commands()
Command.init_counters()
puts("done.")
Log.write(2, "Commands registered.")
if Options.io_type.to_s == "thread"
  print("Initializing mutexes... ")
  Mod.init_locks()
  Server.init_locks()
  puts("done.")
  Log.write(2, "Mutexes initialized.")
end
print("Initializing server statistics... ")
Server.init_chanmap()
Server.channel_count = 0
Server.friendly_start_date = Time.now.asctime
Server.start_timestamp = Time.now.to_i
Server.oper_count = 0
Server.link_count = 0
Server.visible_count = 0
Server.invisible_count = 0
# FixMe: Calculate global_users and max count later
Server.global_users = 0
Server.global_users_max = 0
puts("done.")
Log.write(2, "Server statistics initialized.")
print("Loading modules... ")
Modules.parse(false)
# The modules below need to be initialized in the server class before the network starts
whowas_loaded = Command.command_map["WHOWAS"]
unless whowas_loaded == nil
  Server.init_whowas()
end
# ToDo: Add G-line mod check here
kline_loaded = Command.command_map["KLINE"]
unless kline_loaded == nil
  Server.init_kline()
end
qline_loaded = Command.command_map["QLINE"]
unless qline_loaded == nil
  Server.init_qline()
end
vhost_loaded = Command.command_map["VHOST"]
unless vhost_loaded == nil
  Server.init_vhost()
end
zline_loaded = Command.command_map["ZLINE"]
unless zline_loaded == nil
  Server.init_zline()
end
puts("done.")
Log.write(2, "Modules loaded.")
puts("Going into daemon mode and waiting for incoming connections... ")
Log.write(2, "Going into daemon mode and waiting for incoming connections... ")
if RUBY_PLATFORM == "java" && ARGV[0] != "-f"
  puts("You are using JRuby which does not support fork()!")
elsif ARGV[0] != "-f"
  exit if fork
  Process.setsid
  exit if fork
  STDIN.reopen "/dev/null"
  STDOUT.reopen "/dev/null", "a"
  STDERR.reopen "/dev/null", "a"
  Process.daemon(nochdir=true, noclose=false)
  begin
    pid_file = File.open("rubircd.pid", 'w')
    pid_file.puts(Process.pid)
    pid_file.close()
  rescue
    Log.write(3, "Unable to write rubircd.pid file!")
    # FixMe: Should we exit here to make the user fix the PID file problem?
  end
end
if Options.io_type.to_s == "em"
  EventMach.start()
else
  Network.start()
end
