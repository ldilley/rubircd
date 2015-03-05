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

class Xline
  def initialize(target, create_time, duration, creator, reason)
    @target = target
    if create_time == nil
      @create_time = Time.now.to_i
    else
      @create_time = create_time
    end
    @duration = duration
    @creator = creator
    @reason = reason
  end

  attr_reader :target, :create_time, :duration, :creator, :reason
end
