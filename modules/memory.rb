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
  # Displays memory statistics and manages garbage collection
  class Memory
    def initialize
      @command_name = 'memory'
      @command_proc = proc { |user, args| on_memory(user, args) }
    end

    def plugin_init(caller)
      caller.register_command(@command_name, @command_proc)
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
    end

    attr_reader :command_name

    @gc_enabled = true

    # Iterates over the hash returned by GC.stat
    def iter_hash(user, hash)
      hash.each do |key, value|
        # Recursion needed for nested hashes when using the JVM (JRuby)
        if value.is_a?(Hash)
          Network.send(user, Numeric.rpl_debugmsg(user.nick, format('%s:', key)))
          iter_hash(user, value)
        else
          Network.send(user, Numeric.rpl_debugmsg(user.nick, format('%s = %s', key, value)))
        end
      end
    end

    # args[0] = subcommand
    def on_memory(user, args)
      unless user.admin
        Network.send(user, Numeric.err_noprivileges(user.nick))
        return
      end
      if args.length < 1
        Network.send(user, Numeric.err_needmoreparams(user.nick, 'MEMORY'))
        return
      end

      case args[0]
      when /^gcoff$/i # disables garbage collection
        GC.disable
        @gc_enabled = false
        Network.send(user, Numeric.rpl_debugmsg(user.nick, 'Garbage collection disabled.'))
        Log.write(0, 'Garbage collection disabled.')
      when /^gcon$/i  # enables garbage collection
        GC.enable
        @gc_enabled = true
        Network.send(user, Numeric.rpl_debugmsg(user.nick, 'Garbage collection enabled.'))
        Log.write(0, 'Garbage collection enabled.')
      when /^gcrun$/i # run garbage collector
        if @gc_enabled
          GC.start
          Network.send(user, Numeric.rpl_debugmsg(user.nick, 'Garbage collection requested.'))
          Log.write(0, 'Garbage collection requested.')
        else
          Network.send(user, Numeric.rpl_debugmsg(user.nick, 'Garbage collection is currently disabled.'))
        end
      when /^stats$/i # memory statistics
        iter_hash(user, GC.stat)
      else
        Network.send(user, Numeric.rpl_debugmsg(user.nick, 'Invalid command'))
        Network.send(user, Numeric.rpl_debugmsg(user.nick, 'Valid commands:'))
        Network.send(user, Numeric.rpl_debugmsg(user.nick, 'gcoff - Disables garbage collection'))
        Network.send(user, Numeric.rpl_debugmsg(user.nick, 'gcon  - Enables garbage collection'))
        Network.send(user, Numeric.rpl_debugmsg(user.nick, 'gcrun - Request garbage collection'))
        Network.send(user, Numeric.rpl_debugmsg(user.nick, 'stats - Displays memory statistics'))
      end
      Network.send(user, Numeric.rpl_endofdebugmsg(user.nick))
    end
  end
end
Optional::Memory.new
