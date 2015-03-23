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
require 'xline'

module Standard
  # Removes a local nick reservation (quarantine) if only nick is given and exists
  # Otherwise, three arguments are required to add a new local nick reservation
  # If the duration is 0 (zero), then the reservation never expires
  # Use is limited to administrators
  class Qline
    def initialize
      @qline_data = []
      @qline_data_lock = Mutex.new if Options.io_type.to_s == 'thread'
      @command_name = 'qline'
      @command_proc = proc { |user, args| on_qline(user, args) }
    end

    def plugin_init(caller)
      caller.register_command(@command_name, @command_proc)
      read_config
      Server.init_qline
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
    end

    attr_reader :command_name

    def list_qlines
      if Options.io_type.to_s == 'thread'
        @qline_data_lock.synchronize { @qline_data }
      else
        @qline_data
      end
    end

    # args[0] = nick
    # args[1] = duration in hours
    # args[2] = reason
    def on_qline(user, args)
      args = args.join.split(' ', 3)
      unless user.is_operator? || user.is_admin? || user.is_service?
        Network.send(user, Numeric.err_noprivileges(user.nick))
        return
      end
      if args.length < 1 || args.length == 2
        Network.send(user, Numeric.err_needmoreparams(user.nick, 'QLINE'))
        return
      end
      if args.length == 1 # attempt to remove the qline
        qline_found = false
        if @qline_data.length > 0
          @qline_data.each do |q|
            next unless args[0].casecmp(q.target) == 0
            if Options.io_type.to_s == 'thread'
              @qline_data_lock.synchronize { @qline_data.delete(q) }
            else
              @qline_data.delete(k)
            end
            qline_found = true
          end
        end
        begin
          marked_for_deletion = false
          qline_entries = ''
          qf = File.open('cfg/qlines.yml', 'r')
          YAML.load_documents(qf) do |doc|
            unless doc.nil?
              doc.each do |key, value|
                if key == 'nick' && value.casecmp(args[0]) == 0
                  marked_for_deletion = true
                  break
                end
              end
            end
            unless marked_for_deletion
              qline_entries += doc.to_yaml
              marked_for_deletion = false
            end
          end
          qf.close
          qf = File.open('cfg/qlines.yml', 'w')
          qf.write(qline_entries)
          qf.close
        rescue => e
          Log.write(3, 'Unable to modify qlines.yml file!')
          Log.write(3, e)
        end
        if qline_found
          Server.users.each do |u|
            if u.is_admin? || u.is_operator?
              Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick}!#{user.ident}@#{user.hostname} has removed a q-line for: #{args[0]}")
            end
          end
        else
          Network.send(user, ":#{Options.server_name} NOTICE #{user.nick} :*** NOTICE: There are no q-lines matching #{args[0]}. For a list, use /STATS q.")
        end
        return
      end
      return unless args.length >= 3
      # Attempt to add the q-line
      args[2] = args[2][1..-1] if args[2][0] == ':' # remove leading ':'
      # Verify this is not a duplicate entry
      if @qline_data.length > 0
        @qline_data.each do |q|
          if args[0].casecmp(q.target) == 0
            Network.send(user, ":#{Options.server_name} NOTICE #{user.nick} :*** NOTICE: There is an existing q-line matching #{args[0]}. For a list, use /STATS q.")
            return
          end
        end
      end
      # Validate nick and duration
      unless args[0] =~ /\A[a-z_\-\[\]\\^{}|`][a-z0-9_\-\[\]\\^{}|`]*\z/i && args[0].length <= Limits::NICKLEN
        if args[0].nil? || args[0] == ''
          Network.send(user, ":#{Options.server_name} NOTICE #{user.nick} :*** NOTICE: Invalid nick in q-line. It was empty!")
        else
          Network.send(user, ":#{Options.server_name} NOTICE #{user.nick} :*** NOTICE: Invalid nick in q-line: #{args[0]}")
        end
        return
      end
      unless args[1] =~ /\d/ && args[1].to_i >= 0
        Network.send(user, ":#{Options.server_name} NOTICE #{user.nick} :*** NOTICE: Invalid duration in q-line: #{args[1]}")
        return
      end
      entry = Xline.new(args[0], nil, args[1], user.nick, args[2])
      if Options.io_type.to_s == 'thread'
        @qline_data_lock.synchronize { @qline_data.push(entry) }
      else
        @qline_data << entry
      end
      begin
        qline_file = File.open('cfg/qlines.yml', 'a')
        qline_file.write({ 'nick' => entry.target, 'create_time' => entry.create_time, 'duration' => entry.duration, 'creator' => entry.creator, 'reason' => entry.reason }.to_yaml)
        qline_file.close
      rescue => e
        Log.write(3, 'Unable to write to qlines.yml file!')
        Log.write(3, e)
      end
      Server.users.each do |u|
        next unless u.is_admin? || u.is_operator?
        if args[1].casecmp('0') == 0
          Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick}!#{user.ident}@#{user.hostname} has issued a q-line for #{args[0]}: #{args[2]}")
        else
          Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick}!#{user.ident}@#{user.hostname} has issued a q-line for #{args[0]} (#{args[1]} hours): #{args[2]}")
        end
      end
      if args[1].casecmp('0') == 0
        Log.write(2, "#{user.nick}!#{user.ident}@#{user.hostname} has issued a q-line for #{args[0]}: #{args[2]}")
      else
        Log.write(2, "#{user.nick}!#{user.ident}@#{user.hostname} has issued a q-line for #{args[0]} (#{args[1]} hours): #{args[2]}")
      end
    end

    def read_config
      begin
        qline_file = File.open('cfg/qlines.yml', 'r')
      rescue => e
        Log.write(3, 'Unable to open qlines.yml file!')
        Log.write(3, e)
        return
      end
      begin
        YAML.load_documents(qline_file) do |doc|
          qline_fields = []
          unless doc.nil?
            doc.each do |key, value|
              if value.nil? || value == ''
                Log.write(4, "Invalid #{key} (null value) in qlines.yml file!")
                # TODO: Make this more resilient.
                exit! # bail here and make the administrator repair the file since this will cause problems with STATS q
              end
              qline_fields << value
            end
          end
          # q-line fields
          # 0 = nick
          # 1 = create_time
          # 2 = duration
          # 3 = creator
          # 4 = reason
          entry = Xline.new(qline_fields[0], qline_fields[1], qline_fields[2], qline_fields[3], qline_fields[4])
          if Options.io_type.to_s == 'thread'
            @qline_data_lock.synchronize { @qline_data.push(entry) }
          else
            @qline_data << entry
          end
        end
      rescue => e
        Log.write(3, "qlines.yml file seems corrupt: #{e}")
        return
      ensure
        Log.write(2, "#{@qline_data.length} q-lines loaded.")
        qline_file.close
      end
    end
  end
end
Standard::Qline.new
