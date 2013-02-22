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
  class Lusers
    def initialize()
      @command_name = "lusers"
      @command_proc = Proc.new() { |user| on_lusers(user) }
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

    # This command takes no args and is not RFC compliant as a result (behaves the same way on InspIRCd)
    def on_lusers(user)
      Network.send(user, Numeric.RPL_LUSERCLIENT(user.nick))
      Network.send(user, Numeric.RPL_LUSEROP(user.nick))
      Network.send(user, Numeric.RPL_LUSERCHANNELS(user.nick))
      Network.send(user, Numeric.RPL_LUSERME(user.nick))
      Network.send(user, Numeric.RPL_LOCALUSERS(user.nick))
      Network.send(user, Numeric.RPL_GLOBALUSERS(user.nick))
    end
  end
end
Standard::Lusers.new
