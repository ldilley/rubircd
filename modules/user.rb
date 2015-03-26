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

module Standard
  # Used to register your session with the server
  # This takes place only once upon connecting
  class User
    def initialize
      @command_name = 'user'
      @command_proc = proc { |user, args| on_user(user, args) }
    end

    def plugin_init(caller)
      caller.register_command(@command_name, @command_proc)
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
    end

    attr_reader :command_name

    # args[0] = ident/username
    # args[1] = sometimes ident or hostname (can be spoofed... so we ignore this arg)
    # args[2] = server name (can also be spoofed... so we ignore this arg too)
    # args[3] = gecos/real name
    def on_user(user, args)
      args = args.join.split(' ', 4)
      if args.length < 4
        Network.send(user, Numeric.err_needmoreparams(user.nick, 'USER'))
        return
      end
      if user.registered
        Network.send(user, Numeric.err_alreadyregistered(user.nick))
        return
      end
      # We don't care about the 2nd and 3rd fields since they are supposed to be hostname and server (these can be spoofed for users)
      # The 2nd field also matches the 1st (ident string) for certain clients (FYI)
      # Truncate ident if it is too long
      args[0] = args[0][0..Limits::IDENTLEN - 1] if args[0].length > Limits::IDENTLEN
      if args[0] =~ /\A[a-z_\-\[\]\\^{}|`][a-z0-9_\-\[\]\\^{}|`]*\z/i
        user.ident = args[0]
        args[3] = args[3][1..-1] if args[3][0] == ':' # remove leading ':'
        # Truncate gecos if it is too long
        args[3] = args[3][0..Limits::GECOSLEN - 1] if args[3].length > Limits::GECOSLEN
        user.gecos = args[3]
      else
        Network.send(user, Numeric.err_invalidusername(user.nick, args[0])) # invalid ident
      end
    end
  end
end
Standard::User.new
