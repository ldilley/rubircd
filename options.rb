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

require 'yaml'
require_relative 'user'
require_relative 'utility'

class Options
  @@admin_name = nil
  @@admin_nick = nil
  @@admin_email = nil
  @@network_name = nil
  @@server_name = nil
  @@server_description = nil
  @@listen_port = nil
  @@ssl_port = nil
  @@max_clones = nil
  @@cloak_host = nil
  @@debug_mode = nil

  # If called_from_rehash is true, we make this method more resilient so it will not bring down the server while it is up
  def self.parse(called_from_rehash)
    begin
      options_file=YAML.load_file("cfg/options.yml")
    rescue => e
      return e if called_from_rehash
      puts("failed. Unable to open options.yml file!")
      exit!
    end
    @@admin_name = options_file["admin_name"]
    @@admin_nick = options_file["admin_nick"]
    @@admin_email = options_file["admin_email"]
    @@network_name = options_file["network_name"]
    @@server_name = options_file["server_name"]
    @@server_description = options_file["server_description"]
    unless called_from_rehash # changing these options while the server is already up is currently not supported
      @@listen_host = options_file["listen_host"]
      @@listen_port = options_file["listen_port"]
      @@ssl_port = options_file["ssl_port"]
      @@io_type = options_file["io_type"]
      @@debug_mode = options_file["debug_mode"]
    end
    @@max_connections = options_file["max_connections"]
    @@max_clones = options_file["max_clones"]
    @@cloak_host = options_file["cloak_host"]
    @@auto_cloak = options_file["auto_cloak"]
    @@control_hash = options_file["control_hash"]
    @@server_hash = options_file["server_hash"]

    if @@admin_name == nil
      error_text = "\nUnable to read admin_name option from options.yml file!"
      return Exception.new(error_text.lstrip) if called_from_rehash
      puts(error_text)
      exit!
    end

    if @@admin_nick == nil
      error_text = "\nUnable to read admin_nick option from options.yml file!"
      return Exception.new(error_text.lstrip) if called_from_rehash
      puts(error_text)
      exit!
    end

    if @@admin_email == nil
      error_text = "\nUnable to read admin_email option from options.yml file!"
      return Exception.new(error_text.lstrip) if called_from_rehash
      puts(error_text)
      exit!
    end

    if @@network_name == nil
      error_text = "\nUnable to read network_name option from options.yml file!"
      return Exception.new(error_text.lstrip) if called_from_rehash
      puts(error_text)
      exit!
    end

    if @@server_name == nil
      error_text = "\nUnable to read server_name option from options.yml file!"
      return Exception.new(error_text.lstrip) if called_from_rehash
      puts(error_text)
      exit!
    end

    if @@server_description == nil
      error_text = "\nUnable to read server_description option from options.yml file!"
      return Exception.new(error_text.lstrip) if called_from_rehash
      puts(error_text)
      exit!
    end

    if @@listen_port == nil
      error_text = "\nUnable to read listen_port option from options.yml file!"
      return Exception.new(error_text.lstrip) if called_from_rehash
      puts(error_text)
      exit!
    end

    if @@max_connections == nil
      error_text = "\nUnable to read max_connections option from options.yml file!"
      return Exception.new(error_text.lstrip) if called_from_rehash
      puts(error_text)
      exit!
    end

    if @@io_type == nil
      error_text = "\nUnable to read io_type option from options.yml file!"
      return Exception.new(error_text.lstrip) if called_from_rehash
      puts(error_text)
      exit!
    end

    if @@debug_mode == nil
      error_text = "\nUnable to read debug_mode option from options.yml file!"
      return Exception.new(error_text.lstrip) if called_from_rehash
      puts(error_text)
      exit!
    end

    if @@control_hash == nil
      error_text = "\nUnable to read control_hash option from options.yml file!"
      return Exception.new(error_text.lstrip) if called_from_rehash
      puts(error_text)
      exit!
    end

    if @@listen_port <= 0 || @@listen_port >= 65536
      error_text = "\nlisten_port value is out of range!"
      return Exception.new(error_text.lstrip) if called_from_rehash
      puts(error_text)
      exit!
    end

    unless @@ssl_port == nil
      begin
        if @@ssl_port <= 0 || @@ssl_port >= 65536
          error_text = "\nssl_port value is out of range!"
          return Exception.new(error_text.lstrip) if called_from_rehash
          puts(error_text)
          exit!
        end
      rescue
        error_text = "\nInvalid ssl_port value!"
        return Exception.new(error_text.lstrip) if called_from_rehash
        puts(error_text)
        exit!
      end
    end

    if @@listen_port == @@ssl_port
      error_text = "\nlisten_port and ssl_port values cannot match!"
      return Exception.new(error_text.lstrip) if called_from_rehash
      puts(error_text)
      exit!
    end

    if @@max_connections < 10
      error_text = "\nmax_connections value is set too low!"
      return Exception.new(error_text.lstrip) if called_from_rehash
      puts(error_text)
      exit!
    end

    unless @@max_clones == nil
      if @@max_clones < 1
        error_text = "\nmax_clones value is set too low!"
        return Exception.new(error_text.lstrip) if called_from_rehash
        puts(error_text)
        exit!
      end
    end

    unless @@cloak_host == nil
      unless Utility.is_valid_hostname?(@@cloak_host) || Utility.is_valid_address?(@@cloak_host)
        error_text = "\ncloak_host value is not a valid hostname or address!"
        return Exception.new(error_text.lstrip) if called_from_rehash
        puts(error_text)
        exit!
      end
    end

    if @@auto_cloak.to_s != "true" && @@auto_cloak.to_s != "false"
      error_text = "\nauto_cloak value should be set to either true or false."
      return Exception.new(error_text.lstrip) if called_from_rehash
      puts(error_text)
      exit!
    end

    if @@auto_cloak.to_s == "true" && @@cloak_host == nil
      error_text = "\nauto_cloak value is set to true when cloak_host is not defined!"
      return Exception.new(error_text.lstrip) if called_from_rehash
      puts(error_text)
      exit!
    end

    if @@io_type.to_s == "em"
      error_text = "\nio_type \"em\" is not fully implemented yet!"
      return Exception.new(error_text.lstrip) if called_from_rehash
      puts(error_text)
      exit!
    end

    if @@io_type.to_s == "cell"
      error_text = "\nio_type \"cell\" is not fully implemented yet!"
      return Exception.new(error_text.lstrip) if called_from_rehash
      puts(error_text)
      exit!
    end

    if @@io_type.to_s != "em" && @@io_type.to_s != "cell" && @@io_type.to_s != "event" && @@io_type.to_s != "thread"
      error_text = "\nio_type value should be set to either em, cell, event, or thread."
      return Exception.new(error_text.lstrip) if called_from_rehash
      puts(error_text)
      exit!
    end

    if @@debug_mode.to_s != "true" && @@debug_mode.to_s != "false"
      error_text = "\ndebug_mode value should be set to either true or false."
      return Exception.new(error_text.lstrip) if called_from_rehash
      puts(error_text)
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

  def self.max_clones
    return @@max_clones
  end

  def self.io_type
    return @@io_type
  end

  def self.debug_mode
    return @@debug_mode
  end

  def self.control_hash
    return @@control_hash
  end

  def self.server_hash
    return @@server_hash
  end
end

class Modules
  # If called_from_rehash is true, we do not want to exit the server process while it is up during a rescue
  def self.parse(called_from_rehash)
    begin
      modules_file=YAML.load_file("cfg/modules.yml")
    rescue => e
      return e if called_from_rehash
      Log.write(3, "Unable to open modules.yml file!")
      return
    end
    modules_file.each do |key, values|
      values.each { |module_name| Command.handle_modload(nil, module_name) }
    end
  end
end

class Opers
  # If called_from_rehash is true, we do not want to exit the server process while it is up during a rescue
  def self.parse(called_from_rehash)
    admin_count = 0
    oper_count = 0
    begin
      opers_file=YAML.load_file("cfg/opers.yml")
    rescue => e
      return e if called_from_rehash
      Log.write(3, "Unable to open opers.yml file!")
      return
    end
    opers_file.each do |key, value|
      if key.to_s == "admins" && value != nil
        admin_count = value.length
        value.each do |subkey|
          if subkey["nick"] == nil || subkey["nick"] == ""
            Log.write(3, "Invalid nick in opers.yml file!")
          end
          if subkey["hash"] == nil || subkey["hash"] == "" || subkey["hash"].length < 32
            Log.write(3, "Invalid hash in opers.yml file!")
          end
          admin = Oper.new(subkey["nick"], subkey["hash"], subkey["host"])
          Server.add_admin(admin)
        end
      end
      if key.to_s == "opers" && value != nil
        oper_count = value.length
        value.each do |subkey|
          if subkey["nick"] == nil || subkey["nick"] == ""
            Log.write(3, "Invalid nick in opers.yml file!")
          end
          if subkey["hash"] == nil || subkey["hash"] == "" || subkey["hash"].length < 32
            Log.write(3, "Invalid hash in opers.yml file!")
          end
          oper = Oper.new(subkey["nick"], subkey["hash"], subkey["host"])
          Server.add_oper(oper)
        end
      end
    end
    Log.write(2, "#{admin_count} admin entries loaded.")
    Log.write(2, "#{oper_count} oper entries loaded.")
  end
end
