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

require 'options'
require 'utility'
require 'xline'

module Standard
  # Removes a local IP ban if only the IP address is given and exists. Otherwise,
  # three arguments are required to add a new local IP ban. If the duration is 0
  # (zero), then the ban never expires. Use is limited to administrators and IRC operators.
  class Zline
    def initialize
      @zline_data = []
      @zline_data_lock = Mutex.new if Options.io_type.to_s == 'thread'
      @command_name = 'zline'
      @command_proc = proc { |user, args| on_zline(user, args) }
    end

    def plugin_init(caller)
      caller.register_command(@command_name, @command_proc)
      read_config
      Server.init_zline
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
    end

    attr_reader :command_name

    def list_zlines
      if Options.io_type.to_s == 'thread'
        @zline_data_lock.synchronize { @zline_data }
      else
        @zline_data
      end
    end

    # args[0] = IP address
    # args[1] = duration in hours
    # args[2] = reason
    def on_zline(user, args)
      args = args.join.split(' ', 3)
      unless user.operator || user.admin || user.service
        Network.send(user, Numeric.err_noprivileges(user.nick))
        return
      end
      if args.length < 1 || args.length == 2
        Network.send(user, Numeric.err_needmoreparams(user.nick, 'ZLINE'))
        return
      end
      if args.length == 1 # attempt to remove the zline
        zline_found = false
        if @zline_data.length > 0
          @zline_data.each do |z|
            next unless args[0].casecmp(z.target) == 0
            if Options.io_type.to_s == 'thread'
              @zline_data_lock.synchronize { @zline_data.delete(z) }
            else
              @zline_data.delete(z)
            end
            zline_found = true
          end
        end
        begin
          marked_for_deletion = false
          zline_entries = ''
          zf = File.open('cfg/zlines.yml', 'r')
          YAML.load_documents(zf) do |doc|
            unless doc.nil?
              doc.each do |key, value|
                if key == 'address' && value.casecmp(args[0]) == 0
                  marked_for_deletion = true
                  break
                end
              end
            end
            unless marked_for_deletion
              zline_entries += doc.to_yaml
              marked_for_deletion = false
            end
          end
          zf.close
          zf = File.open('cfg/zlines.yml', 'w')
          zf.write(zline_entries)
          zf.close
        rescue => e
          Log.write(3, 'Unable to modify zlines.yml file!')
          Log.write(3, e)
        end
        if zline_found
          Server.users.each do |u|
            if u.admin || u.operator
              Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick}!#{user.ident}@#{user.hostname} has removed a z-line for: #{args[0]}")
            end
          end
        else
          Network.send(user, ":#{Options.server_name} NOTICE #{user.nick} :*** NOTICE: There are no z-lines matching #{args[0]}. For a list, use /STATS z.")
        end
        return
      end
      return unless args.length >= 3
      # Attempt to add the z-line
      args[2] = args[2][1..-1] if args[2][0] == ':' # remove leading ':'
      # Verify this is not a duplicate entry
      if @zline_data.length > 0
        @zline_data.each do |z|
          if args[0].casecmp(z.target) == 0
            Network.send(user, ":#{Options.server_name} NOTICE #{user.nick} :*** NOTICE: There is an existing z-line matching #{args[0]}. For a list, use /STATS z.")
            return
          end
        end
      end
      # Validate IP address and duration
      unless Utility.valid_address?(args[0])
        if args[0].nil? || args[0] == ''
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
      if Options.io_type.to_s == 'thread'
        @zline_data_lock.synchronize { @zline_data.push(entry) }
      else
        @zline_data << entry
      end
      begin
        zline_file = File.open('cfg/zlines.yml', 'a')
        zline_file.write({ 'address' => entry.target, 'create_time' => entry.create_time, 'duration' => entry.duration, 'creator' => entry.creator, 'reason' => entry.reason }.to_yaml)
        zline_file.close
      rescue => e
        Log.write(3, 'Unable to write to zlines.yml file!')
        Log.write(3, e)
      end
      Server.users.each do |u|
        next unless u.admin || u.operator
        if args[1].casecmp('0') == 0
          Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick}!#{user.ident}@#{user.hostname} has issued a z-line for #{args[0]}: #{args[2]}")
        else
          Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick}!#{user.ident}@#{user.hostname} has issued a z-line for #{args[0]} (#{args[1]} hours): #{args[2]}")
        end
      end
      if args[1].casecmp('0') == 0
        Log.write(2, "#{user.nick}!#{user.ident}@#{user.hostname} has issued a z-line for #{args[0]}: #{args[2]}")
      else
        Log.write(2, "#{user.nick}!#{user.ident}@#{user.hostname} has issued a z-line for #{args[0]} (#{args[1]} hours): #{args[2]}")
      end
    end

    def read_config
      begin
        zline_file = File.open('cfg/zlines.yml', 'r')
      rescue => e
        Log.write(3, 'Unable to open zlines.yml file!')
        Log.write(3, e)
        return
      end
      begin
        YAML.load_documents(zline_file) do |doc|
          zline_fields = []
          unless doc.nil?
            doc.each do |key, value|
              if value.nil? || value == ''
                Log.write(4, "Invalid #{key} (null value) in zlines.yml file!")
                # TODO: Make this more resilient.
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
          if Options.io_type.to_s == 'thread'
            @zline_data_lock.synchronize { @zline_data.push(entry) }
          else
            @zline_data << entry
          end
        end
      rescue => e
        Log.write(3, "zlines.yml file seems corrupt: #{e}")
        return
      ensure
        Log.write(2, "#{@zline_data.length} z-lines loaded.")
        zline_file.close
      end
    end
  end
end
Standard::Zline.new
