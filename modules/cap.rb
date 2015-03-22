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
  # Lists server capabilities for client extensions such as NAMESX, TLS, and UHNAMES
  # If sending multiple capabilities, the list must be preceded by a ':' and all capabilities
  # separated by a space
  class Cap
    def initialize
      @command_name = 'cap'
      @command_proc = proc { |user, args| on_cap(user, args) }
    end

    def plugin_init(caller)
      caller.register_command(@command_name, @command_proc)
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
    end

    attr_reader :command_name

    # args[0] = subcommand
    # args[1..-1] = capability or space-separated capabilities
    def on_cap(user, args)
      if args.length < 1
        Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, 'CAP'))
        return
      end
      args = args.join.split
      if args.length > 1
        args[1] = args[1][1..-1] if args[1][0] == ':' # remove leading ':'
      end
      case args[0].to_s.upcase
      when 'CLEAR'
        # TODO: Add "-multi-prefix -userhost-in-names -tls" when CLEAR is issued
        Network.send(user, ":#{Options.server_name} CAP #{user.nick} ACK :")
      when 'END'
        user.set_negotiating_cap(false) unless user.is_registered?
      when 'LIST'
        Network.send(user, ":#{Options.server_name} CAP #{user.nick} LIST :")
      when 'LS'
        # TODO: Add "multi-prefix userhost-in-names tls" once NAMESX, UHNAMES, and STARTTLS are supported
        user.set_negotiating_cap(true) unless user.is_registered?
        Network.send(user, ":#{Options.server_name} CAP #{user.nick} LS :")
      when 'REQ'
        # Note: Do not change session capabilities until last ACK is sent per IRC CAP draft
        user.set_negotiating_cap(true) unless user.is_registered?
        # All REQs are bad for now until support for capabilities are added...
        Network.send(user, ":#{Options.server_name} CAP #{user.nick} NAK: #{args[1..-1].join(' ')}")
      else
        Network.send(user, Numeric.ERR_INVALIDCAPCMD(user.nick, args[0]))
      end
    end
  end
end
Standard::Cap.new
