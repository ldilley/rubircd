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
  class Pong
    def initialize()
      @command_name = "pong"
      @command_proc = Proc.new() { |user, args| on_pong(user, args) }
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

    # args[0] = server
    def on_pong(user, args)
      if args.length < 1
        Network.send(user, Numeric.ERR_NOORIGIN(user.nick))
        return
      end
      if Options.server_name.casecmp(args[0]) == 0 || args[0].to_s.casecmp(":#{Options.server_name}") == 0
        user.last_ping = ::Time.now.to_i
      end
    end
  end
end
Standard::Pong.new
