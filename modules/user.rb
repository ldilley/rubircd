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

module Standard
  class User
    def initialize()
      @command_name = "user"
      @command_proc = Proc.new() { |user, args| on_user(user, args) }
    end

    def plugin_init(caller)
      caller.register_command(@command_name, @command_proc)
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
    end

    def command_name
      @command_name
    end

    # args[0] = ident/username
    # args[1] = sometimes ident or hostname (can be spoofed... so we ignore this arg)
    # args[2] = server name (can also be spoofed... so we ignore this arg too)
    # args[3..-1] = gecos/real name
    def on_user(user, args)
      if args.length < 4
        Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "USER"))
        return
      end
      if user.is_registered
        Network.send(user, Numeric.ERR_ALREADYREGISTERED(user.nick))
        return
      end
      ident = args[0]
      # We don't care about the 2nd and 3rd fields since they are supposed to be hostname and server (these can be spoofed for users)
      # The 2nd field also matches the 1st (ident string) for certain clients (FYI)
      if ident.length > Limits::IDENTLEN
        ident = ident[0..Limits::IDENTLEN-1] # truncate ident if it is too long
      end
      if ident =~ /\A[a-z_\-\[\]\\^{}|`][a-z0-9_\-\[\]\\^{}|`]*\z/i
        user.change_ident(ident)
        gecos = args[3..-1].join(" ")
        if gecos[0] == ':'
          gecos = gecos[1..-1] # remove leading ':'
        end
        if gecos.length > Limits::GECOSLEN
          gecos = gecos[0..Limits::GECOSLEN-1] # truncate gecos if it is too long
        end
        user.change_gecos(gecos)
      else
        Network.send(user, Numeric.ERR_INVALIDUSERNAME(user.nick, ident)) # invalid ident
      end
    end
  end
end
Standard::User.new
