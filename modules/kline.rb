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

require 'xline'

module Standard
  class Kline
    def initialize()
      @command_name = "kline"
      @command_proc = Proc.new() { |user, args| on_kline(user, args) }
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

    @@kline_data = []
    if Options.io_type.to_s == "thread"
      @@kline_data_lock = Mutex.new
    end

    # args[0] = ident@host
    # args[1] = duration in hours
    # args[2] = reason
    def on_kline(user, args)
      args = args.join.split(' ', 3)
      unless user.is_operator || user.is_admin || user.is_service
        Network.send(user, Numeric.ERR_NOPRIVILEGES(user.nick))
        return
      end
      if args.length < 1 || args.length == 2
        Network.send(user, Numeric.ERR_NEEDMOREPARAMS(user.nick, "KLINE"))
        return
      end
      if args.length == 1 # attempt to remove the kline
        kline_found = false
        if @@kline_data.length > 0
          @@kline_data.each do |k|
            if args[0].casecmp(k.target) == 0
              if Options.io_type.to_s == "thread"
                @@kline_data_lock.synchronize { @@kline_data.delete(k) }
              else
                @@kline_data.delete(k)
              end
              kline_found = true
            end
          end
        end
        begin
          marked_for_deletion = false
          kline_entries = ""
          kf = File.open("cfg/klines.yml", 'r')
          YAML.load_documents(kf) do |doc|
            unless doc == nil
              doc.each do |key, value|
                if key == "address" && value.casecmp(args[0]) == 0
                  marked_for_deletion = true
                  break
                end
              end
            end
            unless marked_for_deletion
              kline_entries += doc.to_yaml()
              marked_for_deletion = false
            end
          end
          kf.close()
          kf = File.open("cfg/klines.yml", 'w')
          kf.write(kline_entries)
          kf.close()
        rescue => e
          Log.write("Unable to modify klines.yml file!")
          Log.write(e)
        end
        if kline_found
          Server.users.each do |u|
            if u.is_admin || u.is_operator
              Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick}!#{user.ident}@#{user.hostname} has removed a k-line for: #{args[0]}")
            end
          end
        else
          Network.send(user, ":#{Options.server_name} NOTICE #{user.nick} :*** NOTICE: There are no k-lines matching #{args[0]}. For a list, use /STATS k.")
        end
        return
      end
      if args.length >= 3 # attempt to add the k-line
        if args[2][0] == ':'
          args[2] = args[2][1..-1] # remove leading ':'
        end
        # Verify this is not a duplicate entry
        if @@kline_data.length > 0
          @@kline_data.each do |k|
            if args[0].casecmp(k.target) == 0
              Network.send(user, ":#{Options.server_name} NOTICE #{user.nick} :*** NOTICE: There is an existing k-line matching #{args[0]}. For a list, use /STATS k.")
              return
            end
          end
        end
        # Validate ident, host, and duration
        tokens = args[0].split('@', 2) # 0 = ident and 1 = host
        unless tokens[0] =~ /\A[a-z_\-\[\]\\^{}|`][a-z0-9_\-\[\]\\^{}|`]*\z/i
          if tokens[0] == nil || tokens[0] == ""
            Network.send(user, ":#{Options.server_name} NOTICE #{user.nick} :*** NOTICE: Invalid username in k-line. It was empty!")
          else
            Network.send(user, ":#{Options.server_name} NOTICE #{user.nick} :*** NOTICE: Invalid username in k-line: #{tokens[0]}")
          end
          return
        end
        unless tokens[1] == '*' || tokens[1] =~ /^(?:[a-zA-Z0-9]+(?:\-*[a-zA-Z0-9])*\.)+[a-zA-Z]{2,6}$/i
          if tokens[1] == nil || tokens[1] == ""
            Network.send(user, ":#{Options.server_name} NOTICE #{user.nick} :*** NOTICE: Invalid host in k-line. It was empty!")
          else
            Network.send(user, ":#{Options.server_name} NOTICE #{user.nick} :*** NOTICE: Invalid host in k-line: #{tokens[1]}")
          end
          return
        end
        unless args[1] =~ /\d/ && args[1].to_i >= 0
          Network.send(user, ":#{Options.server_name} NOTICE #{user.nick} :*** NOTICE: Invalid duration in k-line: #{args[1]}")
          return
        end
        entry = Xline.new(args[0], nil, args[1], user.nick, args[2])
        if Options.io_type.to_s == "thread"
          @@kline_data_lock.synchronize { @@kline_data.push(entry) }
        else
          @@kline_data << entry
        end
        begin
          kline_file = File.open("cfg/klines.yml", 'a')
          kline_file.write({ "address" => entry.target, "create_time" => entry.create_time, "duration" => entry.duration, "creator" => entry.creator, "reason" => entry.reason }.to_yaml())
          kline_file.close()
        rescue => e
          Log.write("Unable to write to klines.yml file!")
          Log.write(e)
        end
        Server.users.each do |u|
          if u.is_admin || u.is_operator
            if args[1].casecmp("0") == 0
              Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick}!#{user.ident}@#{user.hostname} has issued a k-line for #{args[0]}: #{args[2]}")
            else
              Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick}!#{user.ident}@#{user.hostname} has issued a k-line for #{args[0]} (#{args[1]} hours): #{args[2]}")
            end
          end
        end
        if args[1].casecmp("0") == 0
          Log.write("#{user.nick}!#{user.ident}@#{user.hostname} has issued a k-line for #{args[0]}: #{args[2]}")
        else
          Log.write("#{user.nick}!#{user.ident}@#{user.hostname} has issued a k-line for #{args[0]} (#{args[1]} hours): #{args[2]}")
        end
      end
    end

    def list_klines()
      return @@kline_data
    end

    def read_config()
      begin
        kline_file = File.open("cfg/klines.yml", 'r')
      rescue => e
        Log.write("Unable to open klines.yml file!")
        Log.write(e)
        return
      end
      begin
        YAML.load_documents(kline_file) do |doc|
          kline_fields = Array.new
          unless doc == nil
            doc.each do |key, value|
              if value == nil || value == ""
                Log.write("Invalid #{key} (null value) in klines.yml file!")
                # ToDo: Make this more resilient.
                exit! # bail here and make the administrator repair the file since this will cause problems with STATS k
              end
              kline_fields << value
            end
          end
          # k-line fields
          # 0 = address
          # 1 = create_time
          # 2 = duration
          # 3 = creator
          # 4 = reason
          entry = Xline.new(kline_fields[0], kline_fields[1], kline_fields[2], kline_fields[3], kline_fields[4])
          if Options.io_type.to_s == "thread"
            @@kline_data_lock.synchronize { @@kline_data.push(entry) }
          else
            @@kline_data << entry
          end
        end
      rescue => e
        Log.write("klines.yml file seems corrupt: #{e}")
        return
      ensure
        Log.write("#{@@kline_data.length} k-lines loaded.")
        kline_file.close()
      end      
    end
  end
end
Standard::Kline.new
