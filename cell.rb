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
#  require 'celluloid/current'
  require 'celluloid/autostart'
rescue Gem::LoadError
  puts 'Celluloid-IO gem not found!'
  Log.write(4, 'Celluloid-IO gem not found!')
  exit!
end

# Handles event-driven I/O for network communication
# using Celluloid
# This class should offer better performance than
# native select() since it provides access to libev
# implementations of epoll and kqueue where available
class Cell
  include Celluloid::IO
  finalizer :shutdown
  Celluloid.logger = ::Logger.new('logs/celluloid.log')

  def initialize(host, plain_port, ssl_port)
    # Since Celluloid::IO is included, this is a Celluloid::IO::TCPServer
    if Options.enable_starttls.to_s == 'false'
      @plain_server = TCPServer.new(host, plain_port)
    else
      tls_context = OpenSSL::SSL::SSLContext.new
      tls_context.ca_file = 'cfg/ca.pem' if File.exists?('cfg/ca.pem')
      tls_context.cert = OpenSSL::X509::Certificate.new(File.read('cfg/cert.pem'))
      tls_context.key = OpenSSL::PKey::RSA.new(File.read('cfg/key.pem'))
      tls_server = SSLServer.new(TCPServer.new(host, plain_port), tls_context)
      tls_server.start_immediately = false # don't start SSL handshake until client issues "STARTTLS"
      @plain_server = tls_server           # plain_server is now an SSLServer
    end
    async.plain_acceptor
    return if Options.ssl_port.nil?
    ssl_context = OpenSSL::SSL::SSLContext.new
    ssl_context.ca_file = 'cfg/ca.pem' if File.exists?('cfg/ca.pem')
    ssl_context.cert = OpenSSL::X509::Certificate.new(File.read('cfg/cert.pem'))
    ssl_context.key = OpenSSL::PKey::RSA.new(File.read('cfg/key.pem'))
    @ssl_server = SSLServer.new(TCPServer.new(host, ssl_port), ssl_context)
    async.ssl_acceptor
    @connection_check_thread = Thread.new { Network.connection_checker }
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
    Server.increment_clients
    user = Network.register_connection(plain_client, nil)
    Network.check_for_kline(user) unless Server.kline_mod.nil?
    Network.welcome(user)
    Network.main_loop(user)
  end

  def handle_ssl_connections(ssl_client)
    Server.increment_clients
    user = Network.register_connection(ssl_client, nil)
    Network.check_for_kline(user) unless Server.kline_mod.nil?
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
