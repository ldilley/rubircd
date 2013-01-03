class Server
  VERSION = "jrIRC v0.1a"
  MODE_ADMIN = 'a'        # is an IRC administrator
  MODE_BOT = 'b'          # is a bot
  MODE_INVISIBLE = 'i'    # invisible in WHO and NAMES output
  MODE_OPERATOR = 'o'     # is an IRC operator
  MODE_PROTECTED = 'p'    # cannot be banned, kicked, or killed
  MODE_REGISTERED = 'r'   # indicates that the nickname is registered
  MODE_SERVER = 's'       # can see server messages such as kills
  MODE_WALLOPS = 'w'      # can receive oper wall messages
  USER_MODES = "abioprsw"
  @@client_count = 0
  @@channel_count = 0
  @@link_count = 0
  @@start_timestamp = 0   # holds server startup date and time
  @@links = Array.new
  @@users = Array.new
end
