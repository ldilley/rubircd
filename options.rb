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

require 'yaml'
require_relative 'user'

class Options
  @@admin_name = nil
  @@admin_nick = nil
  @@admin_email = nil
  @@network_name = nil
  @@server_name = nil
  @@server_description = nil
  @@listen_port = nil
  @@ssl_port = nil
  @@debug_mode = nil

  def self.parse()
    begin
      options_file=YAML.load_file("cfg/options.yml")
    rescue
      puts("failed. Unable to open options.yml file!")
      exit!
    end
    @@admin_name = options_file["admin_name"]
    @@admin_nick = options_file["admin_nick"]
    @@admin_email = options_file["admin_email"]
    @@network_name = options_file["network_name"]
    @@server_name = options_file["server_name"]
    @@server_description = options_file["server_description"]
    @@listen_host = options_file["listen_host"]
    @@listen_port = options_file["listen_port"]
    @@ssl_port = options_file["ssl_port"]
    @@max_connections = options_file["max_connections"]
    @@io_type = options_file["io_type"]
    @@debug_mode = options_file["debug_mode"]

    if @@admin_name == nil
      puts("\nUnable to read admin_name option from options.yml file!")
    end

    if @@admin_nick == nil
      puts("\nUnable to read admin_nick option from options.yml file!")
    end

    if @@admin_email == nil
      puts("\nUnable to read admin_email option from options.yml file!")
    end

    if @@network_name == nil
      puts("\nUnable to read network_name option from options.yml file!")
    end

    if @@server_name == nil
      puts("\nUnable to read server_name option from options.yml file!")
      exit!
    end

    if @@server_description == nil
      puts("\nUnable to read server_description option from options.yml file!")
      exit!
    end

    if @@listen_port == nil
      puts("\nUnable to read listen_port option from options.yml file!")
      exit!
    end

    if @@max_connections == nil
      puts("\nUnable to read max_connections option from options.yml file!")
      exit!
    end

    if @@io_type == nil
      puts("\nUnable to read io_type option from options.yml file!")
      exit!
    end

    if @@debug_mode == nil
      puts("\nUnable to read debug_mode option from options.yml file!")
      exit!
    end

    if @@listen_port <= 0 || @@listen_port >= 65536
      puts("\nlisten_port value is out of range!")
      exit!
    end

    unless @@ssl_port == nil
      begin
        if @@ssl_port <= 0 || @@ssl_port >= 65536
          puts("\nssl_port value is out of range!")
          exit!
        end
      rescue
        puts("\nInvalid ssl_port value!")
        exit!
      end
    end

    if @@listen_port == @@ssl_port
      puts("\nlisten_port and ssl_port values cannot match!")
      exit!
    end

    if @@max_connections < 10
      puts("\nmax_connections value is set too low!")
      exit!
    end

    if @@io_type.to_s == "event"
      puts("\nI/O type \"event\" is not implemented yet!")
      exit!
    end

    if @@io_type.to_s != "event" && @@io_type.to_s != "thread"
      puts("\nio_type value should be set to either event or thread.")
      exit!
    end

    if @@debug_mode.to_s != "true" && @@debug_mode.to_s != "false"
      puts("\ndebug_mode value should be set to either true or false.")
      exit!
    end
  end

  def self.admin_name
    return @@admin_name
  end

  def self.admin_nick
    return @@admin_nick
  end

  def self.admin_email
    return @@admin_email
  end

  def self.network_name
    return @@network_name
  end

  def self.server_name
    return @@server_name
  end

  def self.server_description
    return @@server_description
  end

  def self.listen_host
    return @@listen_host
  end

  def self.listen_port
    return @@listen_port
  end

  def self.ssl_port
    return @@ssl_port
  end

  def self.max_connections
    return @@max_connections
  end

  def self.io_type
    return @@io_type
  end

  def self.debug_mode
    return @@debug_mode
  end
end

class Modules
  def self.parse()
    begin
      modules_file=YAML.load_file("cfg/modules.yml")
    rescue
      Log.write("Unable to open modules.yml file!")
      return
    end
    modules_file.each do |key, values|
      values.each { |module_name| Command.handle_modload(nil, module_name) }
    end
  end
end

class Opers
  def self.parse()
    begin
      opers_file=YAML.load_file("cfg/opers.yml")
    rescue
      Log.write("Unable to open opers.yml file!")
      return
    end
    opers_file.each do |key, value|
      if key.to_s == "admins"
        value.each do |subkey|
          if subkey["nick"] == nil || subkey["nick"] == ""
            Log.write("Invalid nick in opers.yml file!")
          end
          if subkey["hash"] == nil || subkey["hash"] == "" || subkey["hash"].length < 32
            Log.write("Invalid hash in opers.yml file!")
          end
          admin = Oper.new(subkey["nick"], subkey["hash"], subkey["host"])
          Server.add_admin(admin)
        end
      end
      if key.to_s == "opers"
        value.each do |subkey|
          if subkey["nick"] == nil || subkey["nick"] == ""
            Log.write("Invalid nick in opers.yml file!")
          end
          if subkey["hash"] == nil || subkey["hash"] == "" || subkey["hash"].length < 32
            Log.write("Invalid hash in opers.yml file!")
          end
          oper = Oper.new(subkey["nick"], subkey["hash"], subkey["host"])
          Server.add_oper(oper)
        end
      end
    end
    Log.write("Admin/Oper entries loaded.")
  end
end
