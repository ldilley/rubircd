# $Id$
# jrIRC    
# Copyright (c) 2013 (see authors.txt for details) 
# http://www.devux.org/projects/jrirc/
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

class Options
  @@admin_name = nil
  @@admin_nick = nil
  @@admin_email = nil
  @@network_name = nil
  @@server_name = nil
  @@listen_port = nil
  @@debug_mode = nil

  def self.parse()
    options_file=YAML.load_file("options.yml")
    @@admin_name = options_file["admin_name"]
    @@admin_nick = options_file["admin_nick"]
    @@admin_email = options_file["admin_email"]
    @@network_name = options_file["network_name"]
    @@server_name = options_file["server_name"]
    @@listen_port = options_file["listen_port"]
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

    if @@listen_port == nil
      puts("\nUnable to read listen_port option from options.yml file!")
      exit!
    end

    if @@debug_mode == nil
      puts("\nUnable to read debug_mode option from options.yml file!")
      exit!
    end

    if @@listen_port <= 0 || @@listen_port >=65536
      puts("\nlisten_port value is out of range!")
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

  def self.listen_port
    return @@listen_port
  end

  def self.debug_mode
    return @@debug_mode
  end
end # class
