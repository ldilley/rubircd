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
  class Restart
    def initialize()
      @command_name = "restart"
      @command_proc = Proc.new() { |user, args| on_restart(user, args) }
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

    # ToDo: Fix paths since RESTART is now a module and in a different directory
    # args[0] = password
    def on_restart(user, args)
      unless user.is_admin
        Network.send(user, Numeric.ERR_NOPRIVILEGES(user.nick))
        return
      end
      if args.length < 1
        Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "RESTART"))
        return
      end
      hash = Digest::SHA2.new(256) << args[0].strip
      if Options.control_hash == hash.to_s
        Server.users.each do |u|
          if u.umodes.include?('s')
            Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} has issued a server restart.")
          end
        end
        # ToDo: Write any klines, etc.)
        Log.write("RESTART issued by #{user.nick}!#{user.ident}@#{user.hostname}.")
        if RbConfig::CONFIG['host_os'] =~ /mswin|win|mingw/
          if RUBY_PLATFORM == "java"
            exec("start cmd /C #{File.expand_path(File.dirname(__FILE__))}/rubircd.bat")
          else
            exec("start cmd /C ruby #{File.expand_path(File.dirname(__FILE__))}/rubircd.rb")
          end
        else
          if RUBY_PLATFORM == "java"
            system("kill #{Process.pid} && sleep 5 && #{File.expand_path(File.dirname(__FILE__))}/rubircd.sh&")
          else
            system("kill #{Process.pid} && sleep 5 && ruby #{File.expand_path(File.dirname(__FILE__))}/rubircd.rb&")
          end
        end
      else
        Network.send(user, Numeric.ERR_PASSWDMISMATCH(user.nick))
      end
    end
  end
end
Standard::Restart.new
