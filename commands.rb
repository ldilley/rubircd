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

require_relative 'numeric'
require_relative 'options'
require_relative 'server'

class Command
  def self.parse(client, user, input)
    # ping
    if input[0] =~ /(^ping$)/i
      if input.length < 2
        client.puts(Numeric.ERR_NEEDMOREPARAMS(user.nick, "PING"))
        return
      end
      client.puts("PONG #{Options.server_name}")
      return
    end

    # quit
    if input[0] =~ /(^quit$)/i
      client.close
      Server.client_count -= 1
      Server.user_remove(user)
      return
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
    # nick
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
    # user
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
