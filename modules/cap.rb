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
  class Cap
    def initialize()
      @command_name = "cap"
      @command_proc = Proc.new() { |user, args| on_cap(user, args) }
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

    # args[0] = subcommand
    # args[1..-1] = capability or space-separated capabilities
    def on_cap(user, args)
      if args.length < 1
        Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "CAP"))
        return
      end
      args = args.join.split
      if args.length > 1
        if args[1][0] == ':'
          args[1] = args[1][1..-1] # remove leading ':'
        end
      end
      case args[0].to_s.upcase
        when "CLEAR"
          # ToDo: Add "-multi-prefix -userhost-in-names -tls" when CLEAR is issued
          Network.send(user, ":#{Options.server_name} CAP #{user.nick} ACK :")
        when "END"
          unless user.is_registered
            user.is_negotiating_cap = false
          end
        when "LIST"
          Network.send(user, ":#{Options.server_name} CAP #{user.nick} LIST :")
        when "LS"
          # ToDo: Add "multi-prefix userhost-in-names tls" once NAMESX, UHNAMES, and STARTTLS are supported
          unless user.is_registered
            user.is_negotiating_cap = true
          end
          Network.send(user, ":#{Options.server_name} CAP #{user.nick} LS :")
        when "REQ"
          # Note: Do not change session capabilities until last ACK is sent per IRC CAP draft
          unless user.is_registered
            user.is_negotiating_cap = true
          end
          # All REQs are bad for now until support for capabilities are added...
          Network.send(user, ":#{Options.server_name} CAP #{user.nick} NAK: #{args[1..-1].join(" ")}")
        else
          Network.send(user, Numeric.ERR_INVALIDCAPCMD(user.nick, args[0]))
      end
    end
  end
end
Standard::Cap.new
