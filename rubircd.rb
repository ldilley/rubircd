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

# Check Ruby version
if RUBY_VERSION < '1.9'
  puts('RubIRCd requires Ruby >=1.9!')
  exit!
end

# Local class requirements
require_relative 'channel'
require_relative 'eventmach'
require_relative 'log'
require_relative 'network'
require_relative 'options'
require_relative 'server'
require_relative 'user'

# Needed so certain modules can get at classes in this top-level directory
$LOAD_PATH << Dir.pwd

# Print version and initialize logging
puts(Server::VERSION)
print('Initializing logging... ')
Log.write(2, 'Initializing logging...')
puts('done.')
Log.write(2, 'Logging initialized.')

# Parse configuration
print('Parsing options file... ')
Options.parse(false)
puts('done.')
Log.write(2, 'Options loaded.')
EventMach.check_for_em if Options.io_type.to_s == 'em'
Opers.parse(false)
Thread.abort_on_exception = true if Options.debug_mode.to_s == 'true'
if !Options.listen_host.nil? && !Options.ssl_port.nil?
  puts("Server name: #{Options.server_name}\nAddress: #{Options.listen_host}  \
       \nTCP port: #{Options.listen_port}\nSSL port: #{Options.ssl_port}")
elsif !Options.listen_host.nil? && Options.ssl_port.nil?
  puts("Server name: #{Options.server_name}\nAddress: #{Options.listen_host}  \
       \nTCP port: #{Options.listen_port}")
elsif Options.listen_host.nil? && !Options.ssl_port.nil?
  puts("Server name: #{Options.server_name}\nTCP port: #{Options.listen_port} \
       \nSSL port: #{Options.ssl_port}")
else
  puts("Server name: #{Options.server_name}\nTCP port: #{Options.listen_port}")
end
print('Reading MotD... ')
Server.read_motd(false)
puts('done.')
Log.write(2, 'MotD loaded.')

# Load module handler methods
print('Registering commands... ')
Command.register_commands
Command.init_counters
puts('done.')
Log.write(2, 'Commands registered.')
if Options.io_type.to_s == 'thread'
  print('Initializing mutexes... ')
  Mod.init_locks
  Server.init_locks
  puts('done.')
  Log.write(2, 'Mutexes initialized.')
end

# Initialize server variables
print('Initializing server statistics... ')
Server.init_chanmap
Server.channel_count = 0
Server.friendly_start_date = Time.now.asctime
Server.start_timestamp = Time.now.to_i
Server.oper_count = 0
Server.link_count = 0
Server.visible_count = 0
Server.invisible_count = 0
# FIXME: Calculate global_users and max count later
Server.global_users = 0
Server.global_users_max = 0
puts('done.')
Log.write(2, 'Server statistics initialized.')

# Load modules
print('Loading modules... ')
Modules.parse(false)
# The modules below need to be initialized in the server class before the
# network starts.
# TODO: Add G-line mod check here
kline_loaded = Command.command_map['KLINE']
Server.init_kline unless kline_loaded.nil?
qline_loaded = Command.command_map['QLINE']
Server.init_qline unless qline_loaded.nil?
vhost_loaded = Command.command_map['VHOST']
Server.init_vhost unless vhost_loaded.nil?
whowas_loaded = Command.command_map['WHOWAS']
Server.init_whowas unless whowas_loaded.nil?
zline_loaded = Command.command_map['ZLINE']
Server.init_zline unless zline_loaded.nil?
puts('done.')
Log.write(2, 'Modules loaded.')

# Daemonize or run in foreground if using JRuby
puts('Going into daemon mode and waiting for incoming connections... ')
Log.write(2, 'Going into daemon mode and waiting for incoming connections... ')
if RUBY_PLATFORM == 'java' && ARGV[0] != '-f'
  puts('You are using JRuby which does not support fork!')
elsif ARGV[0] != '-f'
  exit if fork
  Process.setsid
  exit if fork
  STDIN.reopen('/dev/null')
  STDOUT.reopen('/dev/null', 'a')
  STDERR.reopen('/dev/null', 'a')
  # Don't chdir to '/' and send output to /dev/null
  Process.daemon(true, false)
  begin
    pid_file = File.open('rubircd.pid', 'w')
    pid_file.puts(Process.pid)
    pid_file.close
  rescue
    Log.write(3, 'Unable to write rubircd.pid file!')
    # FIXME: Should we exit here to make the user fix the PID file problem?
  end
end

# Start the network
if Options.io_type.to_s == 'em'
  EventMach.start
else
  Network.start
end
