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
  # Reports the current time on a given server or current server if no argument is provided
  class Time
    def initialize
      @command_name = 'time'
      @command_proc = proc { |user, args| on_time(user, args) }
    end

    def plugin_init(caller)
      caller.register_command(@command_name, @command_proc)
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
    end

    attr_reader :command_name

    # args[0] = optional server
    def on_time(user, args)
      unless args[0].nil?
        args[0] = args[0][1..-1] if args[0][0] == ':' # remove leading ':'
      end
      if args.length < 1 || args[0].strip.casecmp(Options.server_name) == 0 || args[0].strip.empty?
        Network.send(user, Numeric.rpl_time(user.nick, Options.server_name))
      # elsif to handle arbitrary servers when others are linked
      else
        Network.send(user, Numeric.err_nosuchserver(user.nick, args[0]))
      end
    end
  end
end
Standard::Time.new
