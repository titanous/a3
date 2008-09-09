# a3

a3 (Asterisk-Adhearsion API) is a Sinatra app that brings REST to Asterisk.

## License

Copyright 2008 Jonathan Rudenberg

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>


## Installation

*   Asterisk manager.conf

        [a3]
        secret = chunky_bacon
        deny=0.0.0.0/0.0.0.0
        permit=127.0.0.1/255.255.255.255
        read = system,call,log,verbose,command,agent,user,config
        write = system,call,log,verbose,command,agent,user,config


*   Adhearsion config/startup.rb

        config.asterisk.enable_ami :host => "127.0.0.1", :username => "a3", :password => "chunky_bacon"
        config.enable_drb :port => 8888
        
*   Asterisk extensions.conf

        [a3-call]
        exten => s,1,AGI(agi://127.0.0.1)
        
*   Adhearsion dialplan.rb

        a3_call {
          caller = get_variable('CALLER')
          execute 'SIPAddHeader', '"Call-Info: answer-after=0"' # auto speakerphone for Grandstream GXP-2000, etc
          dial caller
        }