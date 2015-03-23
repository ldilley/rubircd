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

module Optional
  # Forces a given nick to quit the server with an optional quit message
  # This command is limited to administrators and services
  class Fquit
    def initialize
      @command_name = 'fquit'
      @command_proc = proc { |user, args| on_fquit(user, args) }
    end

    def plugin_init(caller)
      Mod.require_dependency('QUIT')
      req_mod = Mod.find('QUIT')
      if req_mod.nil?
        Log.write(3, 'Refusing to load FQUIT module. Unable to load required module: QUIT')
        return
      end
      caller.register_command(@command_name, @command_proc)
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
    end

    attr_reader :command_name

    # args[0] = nick
    # args[1] = optional quit message
    def on_fquit(user, args)
      args = args.join.split(' ', 2)
      unless user.is_admin?
        Network.send(user, Numeric.err_noprivileges(user.nick))
        return
      end
      if args.length < 1
        Network.send(user, Numeric.err_needmoreparams(user.nick, 'FQUIT'))
        return
      end
      target_user = Server.get_user_by_nick(args[0])
      if target_user.nil?
        Network.send(user, Numeric.err_nosuchnick(user.nick, args[0]))
        return
      end
      Server.users.each do |u|
        next unless u.is_admin? || u.is_operator?
        if args.length > 1
          Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} has issued FQUIT for #{args[0]} with message: #{args[1]}")
        else
          Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} has issued FQUIT for #{args[0]}")
        end
      end
      if args.length > 1
        Log.write(2, "FQUIT issued by #{user.nick}!#{user.ident}@#{user.hostname} for #{target_user.nick}!#{target_user.ident}@#{target_user.hostname} with message: #{args[1]}")
      else
        args[1] = '' # set to empty string since on_quit() does not work with nils as the quit message
        Log.write(2, "FQUIT issued by #{user.nick}!#{user.ident}@#{user.hostname} for #{target_user.nick}!#{target_user.ident}@#{target_user.hostname}")
      end
      quit_mod = Mod.find('QUIT')
      if quit_mod.nil?
        Network.send(user, ":#{Options.server_name} NOTICE #{user.nick} :*** NOTICE: FQUIT requires QUIT module, but it is not loaded.")
        Log.write(3, 'FQUIT requires QUIT module, but it is not loaded.')
      else
        quit_mod.on_quit(target_user, args[1])
      end
    end
  end
end
Optional::Fquit.new
