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
  class Rehash
    def initialize()
      @command_name = "rehash"
      @command_proc = Proc.new() { |user, args| on_rehash(user, args) }
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

    # args[0] = config
    # args[1] = server
    def on_rehash(user, args)
      unless user.is_operator || user.is_admin
        Network.send(user, Numeric.ERR_NOPRIVILEGES(user.nick))
        return
      end
      args = args.join.split(' ', 2)
      # ToDo: Add a broadcast message for each rehash type
      if args.length < 1
        # re-read options.yml
      end
      if args.length == 1
        if args[0].to_s.casecmp("modules") == 0
          # re-read modules.yml
        elsif args[0].to_s.casecmp("motd") == 0
          # re-read motd
        elsif args[0].to_s.casecmp("opers") == 0
          # re-read opers.yml
        elsif args[0].to_s.casecmp("options") == 0
          # re-read options.yml
        end
      end
    end
  end
end
Standard::Rehash.new
