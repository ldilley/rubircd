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
      if args.length < 1 # reload of options.yml is the default behavior
        Server.users.each do |u|
          if u.is_admin || u.is_operator
            Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} is rehashing options.yml.")
          end
        end
        reason = Options.parse(true)
        unless reason.is_a?(Exception)
          Network.send(user, Numeric.RPL_REHASHING(user.nick, "options.yml"))
        else
          Network.send(user, Numeric.ERR_FILEERROR(user.nick, reason))
          Log.write(3, "Failed to read options.yml: #{reason}")
        end
      end
      if args.length == 1
        if args[0].to_s.casecmp("modules") == 0
          unless user.is_admin
            Network.send(user, Numeric.ERR_NOPRIVILEGES(user.nick))
            return
          end
          if Mod.modules == nil || Mod.modules.length < 1
            Network.send(user, Numeric.ERR_CANTUNLOADMODULE(user.nick, "", "No modules are currently loaded."))
            return
          end
          Server.users.each do |u|
            if u.is_admin || u.is_operator
              Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} is rehashing modules.yml.")
            end
          end
          Log.write(2, "#{user.nick}!#{user.ident}@#{user.hostname} is rehashing modules.yml.")
          Mod.modules.each_value do |mod|
            begin
              mod.plugin_finish(Command)
            rescue NameError => e
              Network.send(user, Numeric.ERR_CANTUNLOADMODULE(user.nick, "#{mod.command_name}", "Invalid class name."))
              Log.write(2, "#{user.nick}!#{user.ident}@#{user.hostname} attempted to unload module: #{mod}.")
              Log.write(3, e)
              return
            else
              Mod.modules.delete(mod.command_name.upcase)
              Log.write(2, "#{user.nick}!#{user.ident}@#{user.hostname} has successfully unloaded module: #{mod.command_name} (#{mod})")
            end
          end
          reason = Modules.parse(true)
          unless reason.is_a?(Exception)
            Network.send(user, Numeric.RPL_REHASHING(user.nick, "modules.yml"))
          else
            Network.send(user, Numeric.ERR_FILEERROR(user.nick, reason))
            Log.write(3, "Failed to read modules.yml: #{reason}")
          end
        elsif args[0].to_s.casecmp("motd") == 0
          Server.users.each do |u|
            if u.is_admin || u.is_operator
              Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} is rehashing the MotD.")
            end
          end
          Log.write(2, "#{user.nick}!#{user.ident}@#{user.hostname} is rehashing the MotD.")
          reason = Server.read_motd(true)
          unless reason.is_a?(Exception)
            Network.send(user, Numeric.RPL_REHASHING(user.nick, "motd.txt"))
          else
            Network.send(user, Numeric.ERR_FILEERROR(user.nick, reason))
            Log.write(3, "Failed to read motd.txt: #{reason}")
          end
        elsif args[0].to_s.casecmp("opers") == 0
          Server.users.each do |u|
            if u.is_admin || u.is_operator
              Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} is rehashing opers.yml.")
            end
          end
          Log.write(2, "#{user.nick}!#{user.ident}@#{user.hostname} is rehashing opers.yml.")
          reason = Opers.parse(true)
          unless reason.is_a?(Exception)
            Network.send(user, Numeric.RPL_REHASHING(user.nick, "opers.yml"))
          else
            Network.send(user, Numeric.ERR_FILEERROR(user.nick, reason))
            Log.write(3, "Failed to read opers.yml: #{reason}")
          end
        elsif args[0].to_s.casecmp("options") == 0
          Server.users.each do |u|
            if u.is_admin || u.is_operator
              Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} is rehashing options.yml.")
            end
          end
          reason = Options.parse(true)
          unless reason.is_a?(Exception)
            Network.send(user, Numeric.RPL_REHASHING(user.nick, "options.yml"))
          else
            Network.send(user, Numeric.ERR_FILEERROR(user.nick, reason))
            Log.write(3, "Failed to read options.yml: #{reason}")
          end
        end
      end
    end
  end
end
Standard::Rehash.new
