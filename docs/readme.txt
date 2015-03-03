RubIRCd is an IRC server written in Ruby. To get started with your new server, follow these steps:

1.) Modify cfg/options.yml to your liking.

2.) If you want to enable SSL support, use the create_certificate.sh script under the tools/ directory and follow the prompts.
    This script will work under Linux, UNIX, and Cygwin. If you are running Windows, you can download Cygwin and install OpenSSL
    or you can download the OpenSSL binaries/compile from source and run the following command:

    openssl req -x509 -nodes -newkey rsa:1024 -keyout key.pem -out cert.pem -days 365

    Follow the prompts to generate your certificate. Both the key.pem and cert.pem files should be moved to the cfg/ directory.

3.) Modify cfg/motd.txt to your liking.

4.) Generate a password hash for your administrative account using tools/create_password.rb. You just need to run it and provide
    your desired password in plaintext. An example is: ruby tools/create_password.rb s3cr3t!
    This will generate a SHA256 hash of the password which you will copy and paste into cfg/opers.yml.

5.) Modify cfg/opers.yml and add yourself an administrative account. Be sure to use the password hash from step #4 in the password
    field.

6.) If you are using JRuby, start RubIRCd via rubircd.sh or rubircd.bat. These start scripts include some additional optimizations
    that will be helpful. It is highly recommended that you set io_type to "thread" in cfg/options.yml if using JRuby.

    If you are using CRuby/MRI, simply issue: ruby rubircd.rb
    It is highly recommended that you set io_type to "event" in cfg/options.yml if using CRuby/MRI.

    You should also NOT run RubIRCd as the root or Administrator for security reasons.

7.) If you have any issues, please drop by #rubircd on irc.rubircd.rocks for support. You can also submit bug reports and support
    requests at http://www.rubircd.rocks/.

8.) Enjoy!
