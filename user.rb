# $Id$
# RubIRCd - An IRC server written in Ruby
# Copyright (C) 2013 Lloyd Dilley (see authors.txt for details) 
# http://www.rubircd.org/
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

class User
  # Used to create a new user object when a client connects
  def initialize(nick, ident, hostname, ip_address, gecos, socket, thread)
    @nick = nick
    @ident = ident
    @hostname = hostname
    @ip_address = ip_address
    @gecos = gecos
    @is_registered = false
    @socket = socket
    @thread = thread
    @umodes = Array.new
    @channels = Array.new
    @last_activity = Time.now.to_i # used to determine whether the client should be pinged
  end

  def change_nick(new_nick)
    @nick = new_nick
  end

  def change_ident(new_ident)
    @ident = new_ident
  end

  def change_hostname(new_hostname)
    @hostname = new_hostname
  end

  def change_gecos(new_gecos)
    @gecos = new_gecos
  end

  def set_registered
    @is_registered = true
  end

  def add_umode(umode)
    @umodes.push(umode)
  end

  def remove_umode(umode)
    @umodes.delete(umode)
  end

  def add_channel(channel)
    @channels.push(channel)
  end

  def remove_channel(channel)
    @channels.delete(channel)
  end

  attr_reader :nick, :ident, :hostname, :ip_address, :gecos, :is_registered, :thread, :channels
  attr_accessor :socket
end
