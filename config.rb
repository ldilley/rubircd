require 'yaml'

module JRIRC
  class Config
    @@admin_name = nil
    @@admin_nick = nil
    @@admin_email = nil
    @@network_name = nil
    @@server_name = nil
    @@listen_port = nil

    def initialize
      config_file=YAML.load_file("config.yml")
      @@admin_name = config_file["admin_name"]
      @@admin_nick = config_file["admin_nick"]
      @@admin_email = config_file["admin_email"]
      @@network_name = config_file["network_name"]
      @@server_name = config_file["server_name"]
      @@listen_port = config_file["listen_port"]

      if @@admin_name == nil
        puts("\nUnable to read admin_name option from config.yml file!")
      end

      if @@admin_nick == nil
        puts("\nUnable to read admin_nick option from config.yml file!")
      end

      if @@admin_email == nil
        puts("\nUnable to read admin_email option from config.yml file!")
      end

      if @@network_name == nil
        puts("\nUnable to read network_name option from config.yml file!")
      end

      if @@server_name == nil
        puts("\nUnable to read server_name option from config.yml file!")
        exit!
      end

      if @@listen_port == nil
        puts("\nUnable to read listen_port option from config.yml file!")
        exit!
      end

      if @@listen_port <= 0 || @@listen_port >=65536
        puts("\nlisten_port value is out of range!")
        exit!
      end
    end

    def server_name
      return @@server_name
    end

    def listen_port
      return @@listen_port
    end
  end # class
end # module
