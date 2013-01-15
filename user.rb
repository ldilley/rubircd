# $Id$
# jrIRC    
# Copyright (c) 2013 (see authors.txt for details) 
# http://www.devux.org/projects/jrirc/
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
  @nick
  @ident
  @hostname
  @gecos
  @umodes
  @channels
  @last_activity # used to determine whether the client should be pinged

  # Used to create a new user object when a client connects
  def initialize(nick, ident, hostname, gecos)
    @nick = nick
    @ident = ident
    @hostname = hostname
    @gecos = gecos
    @umodes = Array.new
    @channels = Array.new
    @last_activity = Time.now.to_i
  end

  def change_nick(new_nick)
    @nick = new_nick
  end

  def change_ident(new_ident)
    @ident = new_ident
  end

  def change_gecos(new_gecos)
    @gecos = new_gecos
  end

  def add_umode(umode)
    @umodes.push(umode)
  end

  def remove_umode(umode)
    @umodes.delete(umode)
  end

  def add_channel(channel_name)
    @channels.push(channel_name)
  end

  def remove_channel(channel_name)
    @channels.delete(channel_name)
  end

  attr_reader :nick, :ident, :hostname, :gecos, :channels
end
