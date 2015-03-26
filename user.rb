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

# Contains the properties of an IRC user along with some static utility methods
class User
  # Used to create a new user object when a client connects
  def initialize(nick, ident, hostname, ip_address, gecos, socket, thread)
    @nick = nick
    @ident = ident
    @hostname = hostname
    @virtual_hostname = nil         # this field is also used for hostname cloaking (umode +x)
    @server = Options.server_name
    @ip_address = ip_address
    @gecos = gecos
    @registered = false
    @admin = false
    @operator = false
    @service = false
    @nick_registered = false
    @negotiating_cap = false
    @capabilities = {}
    @capabilities[:multiprefix] = false # same as NAMESX, but also applies to WHO output
    @capabilities[:namesx] = false      # multiple prefixes in NAMES output
    @capabilities[:uhnames] = false     # userhost-in-names PROTOCTL equivalent
    @capabilities[:tls] = false         # STARTTLS
    @away_message = ''
    @away_since = nil                   # gets set to current time when calling AWAY
    @socket = socket
    @thread = thread
    @umodes = []
    @invites = []
    @channels = {}
    @session_capabilities = []
    @signon_time = Time.now.to_i
    @last_activity = Time.now.to_i  # used to determine whether the client should be pinged
    @last_ping = Time.now.to_i
    @data_recv = 0                  # amount of data client has received from us in bytes
    @data_sent = 0                  # amount of data client has sent to us in bytes
    return unless Options.io_type.to_s == 'thread'
    # Only create locks for items that can change (ident should not for example)
    @nick_lock = Mutex.new
    @hostname_lock = Mutex.new      # for vhost support
    @away_lock = Mutex.new
    @umodes_lock = Mutex.new
    @invites_lock = Mutex.new
    @channels_lock = Mutex.new
    @activity_lock = Mutex.new
  end

  def nick
    if Options.io_type.to_s == 'thread'
      @nick_lock.synchronize { @nick }
    else
      @nick
    end
  end

  def nick=(nick)
    @nick_lock.lock if Options.io_type.to_s == 'thread'
    @nick = nick
    @nick_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def hostname
    if Options.io_type.to_s == 'thread'
      @hostname_lock.synchronize do
        return @hostname if @virtual_hostname.nil?
        @virtual_hostname
      end
    else
      return @hostname if @virtual_hostname.nil?
      @virtual_hostname
    end
  end

  def hostname=(hostname)
    @hostname_lock.lock if Options.io_type.to_s == 'thread'
    @hostname = hostname
    @hostname_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def vhost?
    if Options.io_type.to_s == 'thread'
      @hostname_lock.synchronize do
        return false if @virtual_hostname.nil?
        return true
      end
    else
      return false if @virtual_hostname.nil?
      return true
    end
  end

  # There are currently no restrictions on the vhost. It could contain a single word or
  # contain characters that are not allowed in RFC-compliant hostnames/FQDNs.
  def virtual_hostname=(virtual_hostname)
    @hostname_lock.lock if Options.io_type.to_s == 'thread'
    @virtual_hostname = virtual_hostname
    @hostname_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def become_admin
    @admin = true
    add_umode('a')
    Server.oper_count += 1
  end

  def become_operator
    @operator = true
    add_umode('o')
    Server.oper_count += 1
  end

  def away_message=(away_message)
    @away_lock.lock if Options.io_type.to_s == 'thread'
    @away_message = away_message
    if message.length < 1
      @away_since = ''
    else
      @away_since = Time.now.to_i
    end
    @away_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def umodes
    if Options.io_type.to_s == 'thread'
      @umodes_lock.synchronize { @umodes }
    else
      @umodes
    end
  end

  def umode?(umode)
    if Options.io_type.to_s == 'thread'
      @umodes_lock.synchronize { @umodes.include?(umode) }
    else
      @umodes.include?(umode)
    end
  end

  def add_umode(umode)
    @umodes_lock.lock if Options.io_type.to_s == 'thread'
    @umodes.push(umode)
    @umodes_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def remove_umode(umode)
    @umodes_lock.lock if Options.io_type.to_s == 'thread'
    @umodes.delete(umode)
    @admin = false if umode == 'a'
    @operator = false if umode == 'o'
    @umodes_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def invites
    if Options.io_type.to_s == 'thread'
      @invites_lock.synchronize { @invites }
    else
      @invites
    end
  end

  def add_invite(channel)
    @invites_lock.lock if Options.io_type.to_s == 'thread'
    @invites.delete_at(0) if invites.length >= Limits::MAXINVITES
    @invites.push(channel)
    @invites_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def remove_invite(channel)
    @invites_lock.lock if Options.io_type.to_s == 'thread'
    @invites.delete(channel)
    @invites_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def add_channel(channel)
    @channels_lock.lock if Options.io_type.to_s == 'thread'
    @channels[channel] = ''
    @channels_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def remove_channel(channel)
    @channels_lock.lock if Options.io_type.to_s == 'thread'
    @channels.each_key { |c| @channels.delete(c) if c.casecmp(channel) == 0 }
    @channels_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def add_channel_mode(channel, mode)
    @channels_lock.lock if Options.io_type.to_s == 'thread'
    @channels.each_key do |c|
      next unless c.casecmp(channel) == 0
      modes = @channels[c]
      if modes.include?(mode)
        break
      else
        @channels[c] = modes + mode
      end
    end
    @channels_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def remove_channel_mode(channel, mode)
    @channels_lock.lock if Options.io_type.to_s == 'thread'
    @channels.each_key do |c|
      if c.casecmp(channel) == 0
        modes = @channels[c]
        @channels[c] = modes.delete(mode)
      end
    end
    @channels_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def channels_length
    if Options.io_type.to_s == 'thread'
      @channels_lock.synchronize { @channels.length }
    else
      @channels.length
    end
  end

  def channels_array
    if Options.io_type.to_s == 'thread'
      @channels_lock.synchronize { @channels.keys }
    else
      @channels.keys
    end
  end

  def on_channel?(channel)
    if Options.io_type.to_s == 'thread'
      @channels_lock.synchronize do
        @channels.each_key do |c|
          return true if c.casecmp(channel) == 0
        end
        return false
      end
    else
      @channels.each_key do |c|
        return true if c.casecmp(channel) == 0
      end
      return false
    end
  end

  def chanop?(channel)
    @channels.each_key do |c|
      next unless c.casecmp(channel) == 0
      if @channels[c].include?('o')
        return true
      else
        return false
      end
    end
  end

  def halfop?(channel)
    @channels.each_key do |c|
      next unless c.casecmp(channel) == 0
      if @channels[c].include?('h')
        return true
      else
        return false
      end
    end
  end

  def voiced?(channel)
    @channels.each_key do |c|
      next unless c.casecmp(channel) == 0
      if @channels[c].include?('v')
        return true
      else
        return false
      end
    end
  end

  def get_highest_prefix(channel)
    @channels.each_key do |c|
      next unless c.casecmp(channel) == 0
      return '&' if @channels[c].include?('a')
      return '!' if @channels[c].include?('z')
      return '~' if @channels[c].include?('f')
      return '@' if @channels[c].include?('o')
      return '%' if @channels[c].include?('h')
      return '+' if @channels[c].include?('v')
      return '' # no channel mode set for user
    end
  end

  def get_prefixes(channel)
    prefix_list = []
    @channels.each_key do |c|
      next unless c.casecmp(channel) == 0
      prefix_list << '&' if @channels[c].include?('a')
      prefix_list << '!' if @channels[c].include?('z')
      prefix_list << '~' if @channels[c].include?('f')
      prefix_list << '@' if @channels[c].include?('o')
      prefix_list << '%' if @channels[c].include?('h')
      prefix_list << '+' if @channels[c].include?('v')
    end
    prefix_list.join
  end

  def update_last_activity
    @activity_lock.lock if Options.io_type.to_s == 'thread'
    @last_activity = Time.now.to_i
    @activity_lock.unlock if Options.io_type.to_s == 'thread'
  end

  def last_activity
    if Options.io_type.to_s == 'thread'
      @activity_lock.synchronize { @last_activity }
    else
      @last_activity
    end
  end

  attr_reader :server, :ip_address, :admin, :operator, :away_message, :away_since, :thread, :channels, :signon_time
  attr_accessor :ident, :gecos, :registered, :service, :nick_registered, :negotiating_cap, :capabilities, :socket, :last_ping, :data_recv, :data_sent, :session_capabilities
end

# Represents an administrator or IRC operator record
class Oper
  def initialize(nick, hash, host)
    @nick = nick
    @hash = hash
    @host = host
  end

  attr_reader :nick, :hash, :host
end
