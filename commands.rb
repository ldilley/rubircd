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

require_relative 'numerics'
require_relative 'options'
require_relative 'server'

class Command
  @@command_dict = {}

  def self.parse(client, user, input)
    puts(input)
    handler = @@command_dict[input[0].to_s.upcase]
    handler ||= @@default_handler
    handler.call(client, user, input[1..-1])
  end

  def self.register_commands()
    @@command_dict["JOIN"] = Proc.new() {|client, user, args| handle_join(client, user, args)}
    @@command_dict["NICK"] = Proc.new() {|client, user, args| handle_nick(client, user, args)}
    @@command_dict["PING"] = Proc.new() {|client, user, args| handle_ping(client, user, args)}
    @@command_dict["QUIT"] = Proc.new() {|client, user, args| handle_quit(client, user, args)}
    @@command_dict["USER"] = Proc.new() {|client, user, args| handle_user(client, user, args)}
    @@default_handler = Proc.new() {|client, user, args| handle_unknown(client, user, args)}
  end

  def self.handle_join(client, user, args)
  # ToDo: Handle conditions such as invite only and keys later once channels support those modes
    if input.length == 1
      client.puts(Numeric.ERR_NEEDMOREPARAMS(user.nick, "JOIN"))
      return false
    end
    channel = input[1]
    if channel[0] != '#'
      client.puts(Numeric.ERR_NOSUCHCHANNEL(user.nick, channel))
      return false
    end
  end

  def self.handle_nick(client, user, args)
    if input.length == 1
      client.puts(Numeric.ERR_NONICKNAMEGIVEN(user.nick))
      return false
    end
    if input.length > 2
      client.puts(Numeric.ERR_ERRONEOUSNICKNAME(user.nick, input[1..input.length].join(" ")))
      return false
    end
    # We must have exactly 2 tokens so ensure the nick is valid
    if input[1] =~ /\A[a-z_\-\[\]\\^{}|`][a-z0-9_\-\[\]\\^{}|`]*\z/i && input[1].length >=1 && input[1].length <= Limits::NICKLEN
      Server.users.each do |u|
        if u.nick.casecmp(input[1]) == 0
          client.puts(Numeric.ERR_NICKNAMEINUSE("*", input[1]))
          return false
        end
      end
      user.change_nick(input[1])
      return true
    else
      client.puts(Numeric.ERR_ERRONEOUSNICKNAME(user.nick, input[1]))
      return false
    end
  end

  def self.handle_ping(client, user, args)
    if input.length < 2
      client.puts(Numeric.ERR_NEEDMOREPARAMS(user.nick, "PING"))
      return false
    end
    if input[1] != "#{Options.server_name}"
      client.puts(Numeric.ERR_NOSUCHSERVER(user.nick, input[1]))
      return false
    end
    # ToDo: Handle ERR_NOORIGIN (409)
    client.puts("PONG #{Options.server_name}")
    return true
  end

  def self.handle_quit(client, user, args)
    client.close
    Server.client_count -= 1
    Server.user_remove(user)
    return true
  end

  def self.handle_user(client, user, args)
    if input.length < 5
      client.puts(Numeric.ERR_NEEDMOREPARAMS(user.nick, "USER"))
      return false
    end
    if user.is_registered
      client.puts(Numeric.ERR_ALREADYREGISTERED(user.nick))
      return false
    end
    gecos = input[4]
    # We don't care about the 2nd and 3rd fields since they are supposed to be hostname and server (these can be spoofed for users)
    # The 2nd field also matches the 1st (ident string) for certain clients (FYI)
    if input[1].length <= Limits::IDENTLEN && gecos[0] == ':'
      if input[1] =~ /\A[a-z_\-\[\]\\^{}|`][a-z0-9_\-\[\]\\^{}|`]*\z/i
        user.change_ident(input[1])
        gecos = input[4..input.length].join(" ")
        gecos = gecos[1..gecos.length] # remove leading ':'
        # Truncate gecos field if too long
        if gecos.length > Limits::GECOSLEN
          gecos = gecos[0..Limits::GECOSLEN-1]
        end
        user.change_gecos(gecos)
        return true
      else
        clients.puts(Numeric.ERR_INVALIDUSERNAME(user.nick, input[1])) # invalid ident
        return false
      end
    else
      # If we arrive here, just truncate the ident and add the gecos anyway? ToDo: ensure ident is still valid...
      return false # ident too long or invalid gecos
    end
  end

  # admin
  # away
  # connect
  # error
  # info
  # invite
  # ison
  # kick
  # kill
  # links
  # list
  # mode
  # motd
  # names
  # notice
  # oper
  # operwall
  # part
  # pass
  # pong
  # privmsg
  # rehash
  # restart
  # server
  # squit
  # stats
  # summon
  # time
  # topic
  # trace
  # userhost
  # users
  # version
  # who
  # whois
  # whowas

  def self.handle_unknown(client, user, args)
    # If we get here, we've exhausted all commands
    client.puts(Numeric.ERR_UNKNOWNCOMMAND(user.nick, input[0]))
    return
  end

end # class
