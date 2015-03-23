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

# Handles logging
class Log
  def self.write(severity, text)
    # Below actually returns an array, so we check for emptiness and not nil/true/false
    Dir.mkdir('logs') if Dir['logs'].empty?
    case severity
    when 0
      level = 'DBUG'
    when 1
      level = 'AUTH'
    when 2
      level = 'INFO'
    when 3
      level = 'WARN'
    when 4
      level = 'CRIT'
    else
      level = 'DBUG'
    end
    log_file = File.open('logs/rubircd.log', 'a')
    log_file.puts "#{Time.now.asctime} #{level}: #{text}"
    log_file.close
    rescue
      puts 'Unable to write log file!'
  end
end
