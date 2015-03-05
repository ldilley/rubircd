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

require 'xline'

module Standard
  class Zline
    def initialize()
      @command_name = "zline"
      @command_proc = Proc.new() { |user, args| on_zline(user, args) }
    end

    def plugin_init(caller)
      caller.register_command(@command_name, @command_proc)
      read_config()
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
    end

    def command_name
      @command_name
    end

    @@zline_data = []
    if Options.io_type.to_s == "thread"
      @@zline_data_lock = Mutex.new
    end

    # args[0] = IP address
    # args[1] = duration in hours
    # args[2] = reason
    def on_zline(user, args)
      args = args.join.split(' ', 3)
      unless user.is_operator || user.is_admin || user.is_service
        Network.send(user, Numeric.ERR_NOPRIVILEGES(user.nick))
        return
      end
      if args.length < 1 || args.length == 2
        Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "ZLINE"))
        return
      end
      if args.length == 1 # attempt to remove the zline
        zline_found = false
        if @@zline_data.length > 0
          @@zline_data.each do |z|
            if args[0].casecmp(z.target) == 0
              if Options.io_type.to_s == "thread"
                @@zline_data_lock.synchronize { @@zline_data.delete(z) }
              else
                @@zline_data.delete(z)
              end
              zline_found = true
            end
          end
        end
        begin
          marked_for_deletion = false
          zline_entries = ""
          zf = File.open("cfg/zlines.yml", 'r')
          YAML.load_documents(zf) do |doc|
            unless doc == nil
              doc.each do |key, value|
                if key == "address" && value.casecmp(args[0]) == 0
                  marked_for_deletion = true
                  break
                end
              end
            end
            unless marked_for_deletion
              zline_entries += doc.to_yaml()
              marked_for_deletion = false
            end
          end
          zf.close()
          zf = File.open("cfg/zlines.yml", 'w')
          zf.write(zline_entries)
          zf.close()
        rescue => e
          Log.write(3, "Unable to modify zlines.yml file!")
          Log.write(3, e)
        end
        if zline_found
          Server.users.each do |u|
            if u.is_admin || u.is_operator
              Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick}!#{user.ident}@#{user.hostname} has removed a z-line for: #{args[0]}")
            end
          end
        else
          Network.send(user, ":#{Options.server_name} NOTICE #{user.nick} :*** NOTICE: There are no z-lines matching #{args[0]}. For a list, use /STATS z.")
        end
        return
      end
      if args.length >= 3 # attempt to add the z-line
        if args[2][0] == ':'
          args[2] = args[2][1..-1] # remove leading ':'
        end
        # Verify this is not a duplicate entry
        if @@zline_data.length > 0
          @@zline_data.each do |z|
            if args[0].casecmp(z.target) == 0
              Network.send(user, ":#{Options.server_name} NOTICE #{user.nick} :*** NOTICE: There is an existing z-line matching #{args[0]}. For a list, use /STATS z.")
              return
            end
          end
        end
        # Validate IP address and duration
        unless args[0] =~ /^\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b$/
          if args[0] == nil || args[0] == ""
            Network.send(user, ":#{Options.server_name} NOTICE #{user.nick} :*** NOTICE: Invalid IP address in z-line. It was empty!")
          else
            Network.send(user, ":#{Options.server_name} NOTICE #{user.nick} :*** NOTICE: Invalid IP address in z-line: #{args[0]}")
          end
          return
        end
        unless args[1] =~ /\d/ && args[1].to_i >= 0
          Network.send(user, ":#{Options.server_name} NOTICE #{user.nick} :*** NOTICE: Invalid duration in z-line: #{args[1]}")
          return
        end
        entry = Xline.new(args[0], nil, args[1], user.nick, args[2])
        if Options.io_type.to_s == "thread"
          @@zline_data_lock.synchronize { @@zline_data.push(entry) }
        else
          @@zline_data << entry
        end
        begin
          zline_file = File.open("cfg/zlines.yml", 'a')
          zline_file.write({ "address" => entry.target, "create_time" => entry.create_time, "duration" => entry.duration, "creator" => entry.creator, "reason" => entry.reason }.to_yaml())
          zline_file.close()
        rescue => e
          Log.write(3, "Unable to write to zlines.yml file!")
          Log.write(3, e)
        end
        Server.users.each do |u|
          if u.is_admin || u.is_operator
            if args[1].casecmp("0") == 0
              Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick}!#{user.ident}@#{user.hostname} has issued a z-line for #{args[0]}: #{args[2]}")
            else
              Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick}!#{user.ident}@#{user.hostname} has issued a z-line for #{args[0]} (#{args[1]} hours): #{args[2]}")
            end
          end
        end
        if args[1].casecmp("0") == 0
          Log.write(2, "#{user.nick}!#{user.ident}@#{user.hostname} has issued a z-line for #{args[0]}: #{args[2]}")
        else
          Log.write(2, "#{user.nick}!#{user.ident}@#{user.hostname} has issued a z-line for #{args[0]} (#{args[1]} hours): #{args[2]}")
        end
      end
    end

    def list_zlines()
      return @@zline_data
    end

    def read_config()
      begin
        zline_file = File.open("cfg/zlines.yml", 'r')
      rescue => e
        Log.write(3, "Unable to open zlines.yml file!")
        Log.write(3, e)
        return
      end
      begin
        YAML.load_documents(zline_file) do |doc|
          zline_fields = Array.new
          unless doc == nil
            doc.each do |key, value|
              if value == nil || value == ""
                Log.write(4, "Invalid #{key} (null value) in zlines.yml file!")
                # ToDo: Make this more resilient.
                exit! # bail here and make the administrator repair the file since this will cause problems with STATS z
              end
              zline_fields << value
            end
          end
          # z-line fields
          # 0 = address
          # 1 = create_time
          # 2 = duration
          # 3 = creator
          # 4 = reason
          entry = Xline.new(zline_fields[0], zline_fields[1], zline_fields[2], zline_fields[3], zline_fields[4])
          if Options.io_type.to_s == "thread"
            @@zline_data_lock.synchronize { @@zline_data.push(entry) }
          else
            @@zline_data << entry
          end
        end
      rescue => e
        Log.write(3, "zlines.yml file seems corrupt: #{e}")
        return
      ensure
        Log.write(2, "#{@@zline_data.length} z-lines loaded.")
        zline_file.close()
      end      
    end
  end
end
Standard::Zline.new
