require 'socket'

# Configurables
server_name = "irc.devux.org"
port = 1997

server = TCPServer.open(port)
client_count = 0
users = Array.new
loop {
  Thread.start(server.accept) do |client|
    client_count = client_count+1
    done = 0
    client.puts(":#{server_name} NOTICE Auth :*** Looking up your hostname...")
    client.puts(":#{server_name} NOTICE Auth :*** Found your hostname" ) # ToDo: attempt to resolve client IP address
    incoming = client.gets("\r\n").chomp("\r\n")
    puts(incoming.split)
    incoming = client.gets("\r\n").chomp("\r\n")
    puts(incoming.split)
    user = client.gets("\r\n").chomp("\r\n")
    users.push(user)
    while done == 0 do
      client.print("> ")
      message = client.gets("\r\n").chomp("\r\n")
      #message = client.gets()
      #client.puts(message)
      if message == 'quit'
        done = 1
        client.close()
        client_count = client_count-1
        users.delete(user)
      elsif message == 'date' || message == 'time'
        client.puts(Time.now.ctime)
      elsif message == 'who'
        client.puts("Current connections: #{client_count}")
        client.puts("Users online: ")
        users.each { |x| client.puts(x) }
      else
        client.puts("Invalid command")
      end
    end
  end
}
