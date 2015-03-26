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
  # Reloads various configuration files and the MotD
  # If no argument is specified, options.yml is reloaded
  # Use is limited to administrators and IRC operators
  # IRC operators are not able to reload modules however
  class Rehash
    def initialize
      @command_name = 'rehash'
      @command_proc = proc { |user, args| on_rehash(user, args) }
    end

    def plugin_init(caller)
      caller.register_command(@command_name, @command_proc)
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
    end

    attr_reader :command_name

    # args[0] = config
    # args[1] = server
    def on_rehash(user, args)
      unless user.operator || user.admin
        Network.send(user, Numeric.err_noprivileges(user.nick))
        return
      end
      args = args.join.split(' ', 2)
      if args.length < 1 # reload of options.yml is the default behavior
        Server.users.each do |u|
          if u.admin || u.operator
            Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} is rehashing options.yml.")
          end
        end
        reason = Options.parse(true)
        if reason.is_a?(Exception)
          Network.send(user, Numeric.err_fileerror(user.nick, reason))
          Log.write(3, "Failed to read options.yml: #{reason}")
        else
          Network.send(user, Numeric.rpl_rehashing(user.nick, 'options.yml'))
        end
      end
      return unless args.length == 1
      if args[0].to_s.casecmp('modules') == 0
        unless user.admin
          Network.send(user, Numeric.err_noprivileges(user.nick))
          return
        end
        if Mod.modules.nil? || Mod.modules.length < 1
          Network.send(user, Numeric.err_cantunloadmodule(user.nick, '', 'No modules are currently loaded.'))
          return
        end
        Server.users.each do |u|
          if u.admin || u.operator
            Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} is rehashing modules.yml.")
          end
        end
        Log.write(2, "#{user.nick}!#{user.ident}@#{user.hostname} is rehashing modules.yml.")
        Mod.modules.each_value do |mod|
          begin
            mod.plugin_finish(Command)
          rescue NameError => e
            Network.send(user, Numeric.err_cantunloadmodule(user.nick, "#{mod.command_name}", 'Invalid class name.'))
            Log.write(2, "#{user.nick}!#{user.ident}@#{user.hostname} attempted to unload module: #{mod}.")
            Log.write(3, e)
            return
          else
            Mod.modules.delete(mod.command_name.upcase)
            Log.write(2, "#{user.nick}!#{user.ident}@#{user.hostname} has successfully unloaded module: #{mod.command_name} (#{mod})")
          end
        end
        reason = Modules.parse(true)
        if reason.is_a?(Exception)
          Network.send(user, Numeric.err_fileerror(user.nick, reason))
          Log.write(3, "Failed to read modules.yml: #{reason}")
        else
          Network.send(user, Numeric.rpl_rehashing(user.nick, 'modules.yml'))
        end
      elsif args[0].to_s.casecmp('motd') == 0
        Server.users.each do |u|
          if u.admin || u.operator
            Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} is rehashing the MotD.")
          end
        end
        Log.write(2, "#{user.nick}!#{user.ident}@#{user.hostname} is rehashing the MotD.")
        reason = Server.read_motd(true)
        if reason.is_a?(Exception)
          Network.send(user, Numeric.err_fileerror(user.nick, reason))
          Log.write(3, "Failed to read motd.txt: #{reason}")
        else
          Network.send(user, Numeric.rpl_rehashing(user.nick, 'motd.txt'))
        end
      elsif args[0].to_s.casecmp('opers') == 0
        Server.users.each do |u|
          if u.admin || u.operator
            Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} is rehashing opers.yml.")
          end
        end
        Log.write(2, "#{user.nick}!#{user.ident}@#{user.hostname} is rehashing opers.yml.")
        reason = Opers.parse(true)
        if reason.is_a?(Exception)
          Network.send(user, Numeric.err_fileerror(user.nick, reason))
          Log.write(3, "Failed to read opers.yml: #{reason}")
        else
          Network.send(user, Numeric.rpl_rehashing(user.nick, 'opers.yml'))
        end
      elsif args[0].to_s.casecmp('options') == 0
        Server.users.each do |u|
          if u.admin || u.operator
            Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} is rehashing options.yml.")
          end
        end
        reason = Options.parse(true)
        if reason.is_a?(Exception)
          Network.send(user, Numeric.err_fileerror(user.nick, reason))
          Log.write(3, "Failed to read options.yml: #{reason}")
        else
          Network.send(user, Numeric.rpl_rehashing(user.nick, 'options.yml'))
        end
      elsif args[0].to_s.casecmp('vhosts') == 0
        Server.users.each do |u|
          if u.admin || u.operator
            Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} is rehashing vhosts.")
          end
        end
        Command.handle_modreload(user, 'vhost')
      # All xlines
      # TODO: Add g-line in 0.3a
      elsif args[0].to_s.casecmp('klines') == 0
        Server.users.each do |u|
          if u.admin || u.operator
            Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} is rehashing k-lines.")
          end
        end
        Command.handle_modreload(user, 'kline')
      elsif args[0].to_s.casecmp('qlines') == 0
        Server.users.each do |u|
          if u.admin || u.operator
            Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} is rehashing q-lines.")
          end
        end
        Command.handle_modreload(user, 'qline')
      elsif args[0].to_s.casecmp('zlines') == 0
        Server.users.each do |u|
          if u.admin || u.operator
            Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} is rehashing z-lines.")
          end
        end
        Command.handle_modreload(user, 'zline')
      end
    end
  end
end
Standard::Rehash.new
