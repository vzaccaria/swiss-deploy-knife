_               = require('underscore')
_.str           = require('underscore.string');
moment          = require 'moment'
fs              = require 'fs'
color           = require('ansi-color').set
{ spawn, kill } = require('child_process')
__q             = require('q')
sh              = require('shelljs')
os              = require('os')
shelljs         = sh
cl              = require('clark')
ut              = require('utf-8')
winston         = require('winston')

disp-ok = -> winston.info "Ok"
disp-ko = winston.error
disp    = winston.info
pdisp   = console.log
pdeb    = winston.warn


_.mixin(_.str.exports());
_.str.include('Underscore.string', 'string');

_module = ->

    var scope 

    @other-get-credentials = (local) ->
            return require('fs').readFileSync(local.credentials)

    send-command = (conn, c, options) ->
      d = __q.defer()
      disp "Executing command #c"
      output = ""
      register-msg-handlers(conn, d)
      conn.exec c, (err, stream) ->
          if err then 
            d.reject("Exit code: #err")
            return

          stream.on 'data', -> 
                output := output + it
                if not options?.silent?
                    process.stdout.write it

          stream.on 'exit', (code, signal) -> 
            if code isnt 0
              d.reject("Exit code: #code")        
            else
              d.resolve(output)

      return d.promise

    create-connection = ->
        pdeb "Creating connection"
        ssh2 = require('ssh2')
        conn = new ssh2()
        return conn

    connect = (conn, local) ->
        pdeb "Connecting to #{local.hostname}"
        conn.connect {
            host:           local.hostname
            port:           local.port 
            username:       local.username
            private-key:    require('fs').readFileSync(local.credentials)
        }
        return conn

    register-msg-handlers = (conn, defer) ->

        conn.on 'connect', -> 
            pdeb "Connected"

        conn.on 'error', -> 
            defer.reject("Error on connection.") 

        conn.on 'close', ->   
            pdeb "Closed"

    inject = (o) ->
      _.extend(this, o)

    inner-module = ->
      return root

    iface = { 
                inner-module: inner-module
                send-command: send-command 
                create-connection: create-connection
                connect: connect 
                register-msg-handlers: register-msg-handlers
                inject: inject
                }
      
    return iface
 
module.exports = _module()