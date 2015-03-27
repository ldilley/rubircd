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

require 'utility'

module Optional
  # Sets the virtual host of a user
  class Vhost
    def initialize
      @vhosts_data = []
      @vhosts_data_lock = Mutex.new if Options.io_type.to_s == 'thread'
      @command_name = 'vhost'
      @command_proc = proc { |user, args| on_vhost(user, args) }
    end

    def plugin_init(caller)
      caller.register_command(@command_name, @command_proc)
      read_config
      Server.init_vhost
    end

    def plugin_finish(caller)
      caller.unregister_command(@command_name)
    end

    attr_reader :command_name

    # args[0] = nick
    # args[1] = virtual host
    def on_vhost(user, args)
      args = args.join.split(' ', 2)
      unless user.admin
        Network.send(user, Numeric.err_noprivileges(user.nick))
        return
      end
      if args.length < 2
        Network.send(user, Numeric.err_needmoreparams(user.nick, 'VHOST'))
        return
      end
      target_user = Server.get_user_by_nick(args[0])
      if target_user.nil?
        Network.send(user, Numeric.err_nosuchnick(user.nick, args[0]))
        return
      end
      if Utility.valid_hostname?(args[1]) || Utility.valid_address?(args[1])
        target_user.virtual_hostname = args[1]
        Server.users.each do |u|
          if u.admin || u.operator
            Network.send(u, ":#{Options.server_name} NOTICE #{u.nick} :*** BROADCAST: #{user.nick}!#{user.ident}@#{user.hostname} has set the vhost for #{args[0]} to #{args[1]}")
          end
        end
        Log.write(2, "#{user.nick}!#{user.ident}@#{user.hostname} has set the vhost for #{args[0]} to #{args[1]}")
      else
        Network.send(user, ":#{Options.server_name} NOTICE #{user.nick} :*** NOTICE: Invalid vhost: #{args[1]}")
      end
    end

    def read_config
      begin
        vhosts_file = File.open('cfg/vhosts.yml', 'r')
      rescue => e
        Log.write(3, 'Unable to open vhosts.yml file!')
        Log.write(3, e)
        return
      end
      begin
        YAML.load_documents(vhosts_file) do |doc|
          vhost_fields = []
          unless doc.nil?
            doc.each do |key, value|
              if value.nil? || value == ''
                Log.write(4, "Invalid #{key} (null value) in vhosts.yml file!")
                exit!
              end
              vhost_fields << value
            end
          end
          # vhost fields
          # 0 = ident
          # 1 = host
          # 2 = vhost
          unless Utility.valid_hostname?(vhost_fields[1]) || Utility.valid_address?(vhost_fields[1]) || vhost_fields[1] == '*'
            Log.write(3, "Invalid host in vhosts.yml: #{vhost_fields[1]}")
          end
          unless Utility.valid_hostname?(vhost_fields[2]) || Utility.valid_address?(vhost_fields[2])
            Log.write(3, "Invalid vhost in vhosts.yml: #{vhost_fields[2]}")
          end
          entry = { ident: vhost_fields[0], host: vhost_fields[1], vhost: vhost_fields[2] }
          if Options.io_type.to_s == 'thread'
            @vhosts_data_lock.synchronize { @vhosts_data.push(entry) }
          else
            @vhosts_data << entry
          end
        end
      rescue => e
        Log.write(3, "vhosts.yml file seems corrupt: #{e}")
        return
      ensure
        Log.write(2, "#{@vhosts_data.length} vhosts loaded.")
        vhosts_file.close
      end
    end

    def find_vhost(ident, hostname)
      if Options.io_type.to_s == 'thread'
        @vhosts_data_lock.synchronize do
          @vhosts_data.each do |vhost|
            next unless vhost[:ident] == ident || vhost[:ident] == '*'
            if vhost[:host] == hostname || vhost[:host] == '*'
              return vhost[:vhost]
            end
          end
          return nil
        end
      else
        @vhosts_data.each do |vhost|
          next unless vhost[:ident] == ident || vhost[:ident] == '*'
          if vhost[:host] == hostname || vhost[:host] == '*'
            return vhost[:vhost]
          end
        end
        return nil
      end
    end
  end
end
Optional::Vhost.new
