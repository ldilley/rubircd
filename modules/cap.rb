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
        Network.send(user, Numeric.err_needmoreparams(user.nick, 'CAP'))
        return
      end
      args = args.join.split
      if args.length > 1
        args[1] = args[1][1..-1] if args[1][0] == ':' # remove leading ':'
      end
      case args[0].to_s.upcase
      when /^CLEAR$/i
        user.capabilities[:namesx] = false
        user.capabilities[:uhnames] = false
        if Options.enable_starttls.to_s == 'true'
          user.capabilities[:tls] = false
          Network.send(user, ":#{Options.server_name} CAP #{user.nick} ACK :-multi-prefix -userhost-in-names -tls")
        else
          Network.send(user, ":#{Options.server_name} CAP #{user.nick} ACK :-multi-prefix -userhost-in-names")
        end
      when /^END$/i
        user.negotiating_cap = false unless user.registered
      when /^LIST$/i
        client_caps = ''
        client_caps += 'multi-prefix ' if user.capabilities[:namesx]
        client_caps += 'userhost-in-names ' if user.capabilities[:uhnames]
        client_caps += 'tls' if user.capabilities[:tls] && Options.enable_starttls.to_s == 'true'
        Network.send(user, ":#{Options.server_name} CAP #{user.nick} LIST :#{client_caps}")
      when /^LS$/i
        user.negotiating_cap = true unless user.registered
        if Options.enable_starttls.to_s == 'true'
          Network.send(user, ":#{Options.server_name} CAP #{user.nick} LS :multi-prefix userhost-in-names tls")
        else
          Network.send(user, ":#{Options.server_name} CAP #{user.nick} LS :multi-prefix userhost-in-names")
        end
      when /^REQ$/i
        user.negotiating_cap = true unless user.registered
        good_extensions = ''
        bad_extensions = ''
        if args.length > 1
          args[1..-1].each do |extension|
            if extension.casecmp('multi-prefix') == 0
              unless user.capabilities[:namesx]
                good_extensions += 'multi-prefix '
                user.capabilities[:namesx] = true
              end
            elsif extension.casecmp('userhost-in-names') == 0
              unless user.capabilities[:uhnames]
                good_extensions += 'userhost-in-names '
                user.capabilities[:uhnames] = true
              end
            elsif extension.casecmp('tls') == 0
              if Options.enable_starttls.to_s == 'true'
                unless user.capabilities[:tls]
                  good_extensions += 'tls '
                  user.capabilities[:tls] = true
                end
              end
            else
              bad_extensions += "#{extension} "
            end
          end
          unless good_extensions.empty?
            Network.send(user, ":#{Options.server_name} CAP #{user.nick} ACK: #{good_extensions}")
          end
          unless bad_extensions.empty?
            Network.send(user, ":#{Options.server_name} CAP #{user.nick} NAK: #{bad_extensions}")
          end
        end
      else
        Network.send(user, Numeric.err_invalidcapcmd(user.nick, args[0]))
      end
    end
  end
end
Standard::Cap.new
