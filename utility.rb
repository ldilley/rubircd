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

class Utility
  def self.calculate_elapsed_time(start_time)
    current_time = ::Time.now.to_i
    delta = current_time - start_time
    days = delta / (60 * 60 * 24) # 60 seconds in a minute, 60 minutes in an hour, 24 hours in a day
    delta = delta - days * 60 * 60 * 24
    hours = delta / (60 * 60)
    delta = delta - hours * 60 * 60
    minutes = delta / 60
    delta = delta - minutes * 60
    seconds = delta
    return days, hours, minutes, seconds # check for negative values later if it's a problem...
  end
end
