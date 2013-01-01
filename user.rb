class User
  @nick
  @ident
  @hostname
  @gecos
  @umodes
  @channels

  # Used to create a new user object when a client connects
  def initialize(nick, ident, hostname, gecos)
    @nick = nick
    @ident = ident
    @hostname = hostname
    @gecos = gecos
    @umodes = Array.new
    @channels = Array.new
  end

  def change_nick(new_nick)
    @nick = new_nick
  end

  def add_umode(umode)
    @umodes.push(umode)
  end

  def remove_umode(umode)
    @umodes.delete(umode)
  end

  def add_channel(channel_name)
    @channels.push(channel_name)
  end

  def remove_channel(channel_name)
    @channels.delete(channel_name)
  end

  attr_reader :nick, :channels
end
