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
  def self.parse(client, user, input)
    # nick
    if input[0] =~ /(^nick$)/i
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

    # ping
    if input[0] =~ /(^ping$)/i
      if input.length < 2
        client.puts(Numeric.ERR_NEEDMOREPARAMS(user.nick, "PING"))
        return false
      end
      client.puts("PONG #{Options.server_name}")
      return true
    end

    # quit
    if input[0] =~ /(^quit$)/i
      client.close
      Server.client_count -= 1
      Server.user_remove(user)
      return true
    end

    # user
    if input[0] =~ /(^user$)/i
      if input.length < 5
        client.puts(Numeric.ERR_NEEDMOREPARAMS(user.nick, "USER"))
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
          if gecos.length > Limits::GECOSLEN
            gecos = gecos[0..Limits::GECOSLEN-1]
          end
          user.change_gecos(gecos)
          return true
        else
          return false # invalid ident
        end
      else
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
    # join
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

    # If we get here, we've exhausted all commands
    client.puts(Numeric.ERR_UNKNOWNCOMMAND(user.nick, input[0]))
    return
  end
end
