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

require 'socket'
require_relative 'log'
require_relative 'options'
require_relative 'server'

module PlainServer
  def post_init
    Server.increment_clients()
    # ToDo: A lot...
  end

  def receive_data(data)
    puts "Received data: #{data}"
    send_data(data)
  end

  def unbind
    puts "Plain user disconnected."
  end
end

module SecureServer
  def post_init
    start_tls :private_key_file => 'cfg/key.pem', :cert_chain_file => 'cfg/cert.pem', :verify_peer => false
    Server.increment_clients()
    # ToDo: A lot...
  end

  def unbind
    puts "SSL user disconnected."
  end
end

class EventMach
  def self.check_for_em()
    # Check if EventMachine is available
    if Options.io_type.to_s == "em"
      if RUBY_PLATFORM == "java" && Options.ssl_port != nil
        puts "EventMachine does not support SSL/TLS when using JRuby!"
        Log.write(4, "EventMachine does not support SSL/TLS when using JRuby!")
        exit!
      end
      begin
        gem "eventmachine", ">=1.0.3"
        require 'eventmachine'
      rescue Gem::LoadError
        puts "EventMachine gem not found!"
        Log.write(4, "EventMachine gem not found!")
        exit!
      end
    end
  end

  def self.start()
    EventMachine.epoll
    EventMachine.kqueue = true if EM.kqueue? # check if kqueue is available on this platform
    EventMachine::run {
      begin
        if Options.listen_host == nil
          listen_host = "0.0.0.0"
        else
          listen_host = Options.listen_host
        end
        EventMachine::start_server listen_host, Options.listen_port, PlainServer
        if Options.ssl_port != nil
          EventMachine::start_server listen_host, Options.ssl_port, SecureServer
        end
      rescue => e
        puts "Unable to listen on socket."
        puts e
        Log.write(4, "Unable to listen on socket.")
        Log.write(4, e)
        exit!
      end
    }
  end
end
