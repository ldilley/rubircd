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

require 'digest/sha2'
require 'rbconfig'
require_relative 'numerics'
require_relative 'options'
require_relative 'server'

class Command
  @@command_map = {}

  def self.parse(user, input)
    handler = @@command_map[input[0].to_s.upcase]
    if handler == nil
      Network.send(user, Numeric.ERR_UNKNOWNCOMMAND(user.nick, input[0]))
      return
    end
    unless input == nil
      if input.length > 1
        Command.update_counter(input[0].to_s.upcase, input[0].length + 1 + input[1..-1].join.length) # +1 for space between command and args
      else
        Command.update_counter(input[0].to_s.upcase, input[0].length)
      end
    end
    handler.call(user, input[1..-1])
  end

  def self.register_commands()
    @@command_map["MODLIST"] = Proc.new()   { |user, args| handle_modlist(user, args) }
    @@command_map["MODLOAD"] = Proc.new()   { |user, args| handle_modload(user, args) }
    @@command_map["MODRELOAD"] = Proc.new() { |user, args| handle_modreload(user, args) }
    @@command_map["MODUNLOAD"] = Proc.new() { |user, args| handle_modunload(user, args) }
  end

  def self.register_command(command_name, command_proc)
    @@command_map[command_name.upcase] = command_proc
    unless @@command_counter_map.has_key?(command_name.upcase) # preserve stats if reloading module
      @@command_counter_map[command_name.upcase] = Command_Counter.new
    end
  end

  def self.unregister_command(command)
    @@command_map.delete(command.to_s.upcase)
  end

  def self.init_counters()
    @@command_counter_map = {}
    if Options.io_type.to_s == "thread"
      @@command_counter_lock = Mutex.new
    end
    @@command_map.keys.each { |k| @@command_counter_map["#{k}"] = Command_Counter.new }
  end

  def self.update_counter(command, recv_bytes)
    if Options.io_type.to_s == "thread"
      @@command_counter_lock.synchronize do
        @@command_counter_map["#{command}"].increment_counter()
        @@command_counter_map["#{command}"].add_amount_recv(recv_bytes)
      end
    else
      @@command_counter_map["#{command}"].increment_counter()
      @@command_counter_map["#{command}"].add_amount_recv(recv_bytes)
    end
  end

  # MODLIST
  # args[0] = optional server (ToDo: Add ability to specify server to get its modules)
  def self.handle_modlist(user, args)
    unless user.is_admin?
      Network.send(user, Numeric.ERR_NOPRIVILEGES(user.nick))
      return
    end
    if Mod.modules == nil
      Mod.modules = {}
    end
    if Mod.modules.length < 1
      Network.send(user, Numeric.RPL_ENDOFMODLIST(user.nick))
      return
    end
    Mod.modules.each { |key, mod| Network.send(user, Numeric.RPL_MODLIST(user.nick, mod.command_name, mod)) }
    Network.send(user, Numeric.RPL_ENDOFMODLIST(user.nick))
  end

  # MODLOAD
  # args[0] = module
  def self.handle_modload(user, args)
    unless user == nil || user == ""
      unless user.is_admin? 
        Network.send(user, Numeric.ERR_NOPRIVILEGES(user.nick))
        return
      end
    end
    if args == nil
      return
    end
    if args.length < 1
      Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "MODLOAD"))
      return
    end
    if Mod.modules == nil
      Mod.modules = {}
    end
    if args.is_a?(String)
      mod_name = args
    else
      mod_name = args[0]
    end
    if mod_name.length >= 4
      if mod_name[-3, 3] == ".rb"
        mod_name = mod_name[0..-4] # remove .rb extension if the user included it in the module name
      end
    end  
    begin
      new_module = eval(File.read("modules/#{mod_name}.rb"))
      new_module.plugin_init(Command)
    rescue Errno::ENOENT, LoadError, NameError, SyntaxError => e
      if user == nil # called during startup for module autoload, so don't send message down the socket
        puts("Failed to load module: #{mod_name} #{e}")
      elsif user == ""
        # No action required for attempting to load a dependency or performing an ad hoc load
      else
        Network.send(user, Numeric.ERR_CANTLOADMODULE(user.nick, mod_name, e))
        Log.write(2, "#{user.nick}!#{user.ident}@#{user.hostname} attempted to load module: #{mod_name}")
      end
      Log.write(4, "Failed to load module: #{mod_name}: #{e}")
      if user == nil
        exit!        # only exit on startup as to not bring the server down if loading a faulty module
      end
    else
      mod_exists = Mod.modules[mod_name.to_s.upcase]
      unless mod_exists == nil
        unless user == nil || user == ""
          Network.send(user, Numeric.ERR_CANTLOADMODULE(user.nick, mod_name, "Module already loaded @ #{mod_exists}"))
          return
        end
      end
      Mod.add(new_module)
      unless user == nil || user == ""
        Network.send(user, Numeric.RPL_LOADEDMODULE(user.nick, mod_name, new_module))
        Server.users.each do |u|
          if u.umodes.include?('s')
            Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} has loaded module: #{mod_name} (#{new_module})")
          end
        end
        Log.write(2, "#{user.nick}!#{user.ident}@#{user.hostname} called MODLOAD for module: #{mod_name}")
      end
      Log.write(2, "Successfully loaded module: #{mod_name} (#{new_module})")
    end
  end

  # MODRELOAD
  # args[0] = module
  def self.handle_modreload(user, args)
    unless user.is_admin? 
      Network.send(user, Numeric.ERR_NOPRIVILEGES(user.nick))
      return
    end
    if args.length < 1
      Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "MODRELOAD"))
      return
    end
    Command.handle_modunload(user, args)
    Command.handle_modload(user, args)
  end

  # MODUNLOAD
  # args[0] = module
  def self.handle_modunload(user, args)
    unless user.is_admin? 
      Network.send(user, Numeric.ERR_NOPRIVILEGES(user.nick))
      return
    end
    if args.length < 1
      Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "MODUNLOAD"))
      return
    end
    if args.is_a?(String)
      mod_name = args
    else
      mod_name = args[0]
    end
    if Mod.modules == nil || Mod.modules.length < 1
       Network.send(user, Numeric.ERR_CANTUNLOADMODULE(user.nick, mod_name, "No modules are currently loaded."))
      return
    end
    mod = Mod.modules[mod_name.to_s.upcase]
    unless mod == nil
      begin
        mod.plugin_finish(Command)
      rescue NameError => e
        Network.send(user, Numeric.ERR_CANTUNLOADMODULE(user.nick, args[0], "Invalid class name."))
        Log.write(2, "#{user.nick}!#{user.ident}@#{user.hostname} attempted to unload module: #{mod_name}.")
        Log.write(3, e)
        return
      else
        Mod.modules.delete(mod_name.to_s.upcase)
        Network.send(user, Numeric.RPL_UNLOADEDMODULE(user.nick, mod_name, "#{mod}"))
        Server.users.each do |u|
          if u.umodes.include?('s')
            Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick} has unloaded module: #{mod_name} (#{mod})")
          end
        end
        Log.write(2, "#{user.nick}!#{user.ident}@#{user.hostname} has successfully unloaded module: #{mod_name} (#{mod})")
      end
    else
      Network.send(user, Numeric.ERR_CANTUNLOADMODULE(user.nick, mod_name, "Module does not exist."))
    end
  end

  # Standard commands remaining to be implemented:
  # connect  - 0.3a
  # error    - 0.3a
  # gline    - 0.3a
  # links    - 0.3a
  # map      - 0.3a (requires oper/admin privileges)
  # server   - 0.3a
  # squit    - 0.3a
  # trace    - 0.3a

  # Optional service modules to be implemented:
  # botserv  - 0.4a
  # chanserv - 0.4a
  # global   - 0.4a
  # hostserv - 0.4a
  # memoserv - 0.4a
  # nickserv - 0.4a
  # operserv - 0.4a
  # statserv - 0.4a

  # CAPAB, SERVER, PASS, BURST, SJOIN, SMODE? are required for server-to-server linking and data propagation

  # Custom commands that may get implemented as modules:
  # identify - 0.4a
  # ijoin <channel> (administrative command to join a channel while being invisible to its members)
  # jupe - 0.4a
  # knock
  # rules
  # shun
  # silence
  # userip
  # watch

  def self.command_map
    @@command_map
  end

  def self.command_counter_map
    @@command_counter_map
  end
end # class

class Mod
  @@modules = {}

  def self.init_locks()
    @@modules_lock = Mutex.new
  end

  def self.modules
    @@modules
  end

  def self.add(mod)
    if Options.io_type.to_s == "thread"
      @@modules_lock.synchronize { @@modules[mod.command_name.upcase] = mod }
    else
      @@modules[mod.command_name.upcase] = mod
    end
  end

  # Find module by command name
  def self.find(command)
    if Options.io_type.to_s == "thread"
      @@modules_lock.synchronize { return @@modules[command.upcase] }
    else
      return @@modules[command.upcase]
    end
  end

  # Load module if not loaded
  def self.require_dependency(mod_name)
    mod = Mod.find(mod_name.upcase)
    if mod == nil
      Command.handle_modload("", mod_name.downcase)
    end
  end
end

class Command_Counter
  def initialize()
    @command_count = 0
    @command_recv_bytes = 0
  end

  def increment_counter()
    @command_count += 1
  end

  def add_amount_recv(amount)
    @command_recv_bytes += amount
  end

  attr_reader :command_count, :command_recv_bytes
end
