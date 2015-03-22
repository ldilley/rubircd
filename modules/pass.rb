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
  # Sets the connection password to use during registration if the server has one set
  # Has no effect if you are fully registered
  class Pass
    def initialize
      @command_name = 'pass'
      @command_proc = proc { |user, args| on_pass(user, args) }
    end

    def plugin_init(caller)
      caller.register_command(@command_name, @command_proc)
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
    end

    attr_reader :command_name

    # args[0] = password
    def on_pass(user, args)
      if user.is_registered?
        Network.send(user, Numeric.ERR_ALREADYREGISTERED(user.nick))
        return
      end
      if args.length < 1
        Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, 'PASS'))
        return
      end
      hash = Digest::SHA2.new(256) << args[0].strip
      if Options.server_hash == hash.to_s
        return true
      else
        return false
      end
    end
  end
end
Standard::Pass.new
