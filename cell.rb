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

require 'logger'
require_relative 'log'
require_relative 'network'
require_relative 'options'
require_relative 'server'

# Check if Celluloid is available
begin
  gem 'celluloid-io', '>=0.16.0'
  require 'celluloid/io'
  require 'celluloid/autostart'
rescue Gem::LoadError
  puts 'Celluloid-IO gem not found!'
  Log.write(4, 'Celluloid-IO gem not found!')
  exit!
end

class Cell
  include Celluloid::IO
  finalizer :shutdown
  Celluloid.logger = ::Logger.new('logs/celluloid.log')

  def initialize(host, plain_port, ssl_port)
    # Since Celluloid::IO is included, this is a Celluloid::IO::TCPServer
    @plain_server = TCPServer.new(host, plain_port)
    async.plain_acceptor
    unless Options.ssl_port.nil?
      ssl_context = OpenSSL::SSL::SSLContext.new
      ssl_context.cert = OpenSSL::X509::Certificate.new(File.read('cfg/cert.pem'))
      ssl_context.key = OpenSSL::PKey::RSA.new(File.read('cfg/key.pem'))
      @ssl_server = SSLServer.new(TCPServer.new(host, ssl_port), ssl_context)
      async.ssl_acceptor
      @connection_check_thread = Thread.new() { Network.connection_checker() }
    end
  end

  def shutdown
    @plain_server.close if @plain_server
    @ssl_server.close if @ssl_server
  end

  def plain_acceptor
    loop { async.handle_plain_connections(@plain_server.accept) }
  end

  def ssl_acceptor
    loop { async.handle_ssl_connections(@ssl_server.accept) }
  end

  def handle_plain_connections(plain_client)
    Server.increment_clients()
    user = Network.register_connection(plain_client, nil)
    unless Server.kline_mod == nil
      Network.check_for_kline(user)
    end
    Network.welcome(user)
    Network.main_loop(user)
  end

  def handle_ssl_connections(ssl_client)
    Server.increment_clients()
    user = Network.register_connection(ssl_client, nil)
    unless Server.kline_mod == nil
      Network.check_for_kline(user)
    end
    Network.welcome(user)
    Network.main_loop(user)
  end

  def self.start
    if Options.listen_host.nil?
      listen_host = '0.0.0.0'
    else
      listen_host = Options.listen_host
    end
    supervisor = supervise(listen_host, Options.listen_port, Options.ssl_port)
    trap('INT') do
      supervisor.terminate
      exit
    end
    sleep
  end
end
