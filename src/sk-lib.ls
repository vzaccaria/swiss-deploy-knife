_               = require('underscore')
_.str           = require('underscore.string');
moment          = require 'moment'
fs              = require 'fs'
color           = require('ansi-color').set
{ spawn, kill } = require('child_process')
__q             = require('q')
sh              = require('shelljs')


_.mixin(_.str.exports());
_.str.include('Underscore.string', 'string');

debug = false

send-command = (conn, c) ->
  d = __q.defer()
  if debug then console.log "[debug] Executing #c"
  conn.exec c, (err, stream) ->
      if err then 
        d.reject("Exit code: #err")
        return

      stream.on 'data', 
        -> 
            for l in _.lines(it.toString())
               console.log l

      stream.on 'exit', (code, signal) -> 
        if code isnt 0
          d.reject("Exit code: #code")        
        else
          d.resolve("Exit code: #code")

  return d.promise


module.exports.run = (local, command) ->

    e = __q.defer()

    __cnx = require('ssh2')
    conn   = new __cnx()
    conn.connect {
        host:           local.hostname
        port:           local.port 
        username:       local.username
        private-key:    require('fs').readFileSync(local.credentials)
    }

    shutdown-ok = -> 
            conn.end()
            e.resolve()

    shutdown-fail = ->
            conn.end()
            e.reject(it)      

    conn.on 'connect',  -> if debug then console.log "[debug]", color("Connected", \green)
    conn.on 'error',    -> if debug then console.log "[debug]", color(it, \red)
    conn.on 'close',    -> if debug then console.log "[debug]", color("Closed", \green)
    conn.on 'ready',    -> 
        send-command(conn, command).then(shutdown-ok, shutdown-fail)

    return e.promise


rexec = module.exports.run

ch = undefined


module.exports.create-tunnel = (address, through) ->
    # console.log address
    # console.log through
    d = __q.defer()
    if not through?
        console.log "Cannot create tunnel"
        d.reject("Cannot create tunnel")
    else 
        args = [ 
                    '-NL', 
                    "#{address.use}:#{address.hostname}:#{address.port}"
                    "#{through.username}@#{through.hostname}" 
                    ]

        console.log "ssh ", args[0], args[1], args[2]

        ch := spawn 'ssh', args

        # console.log ch.pid
        
        ch.on 'error', -> 
            d.reject("Failed connection")

        ch.stderr.on 'data', ->
            d.reject("Failed connection")

        set-timeout (-> d.resolve()), 500

    return d.promise

module.exports.close-tunnel = ->
   sh.exec("kill -9 #{ch.pid}")
   ch := undefined
   return true


module.exports.namespace = ->
    a = arguments
    name = a[0]
    description = ''
    tasks = {}

    n = 1

    if _.is-string(a[n]) 
        description = a[n] 
        n = n + 1

    for t in a[n to ]
        tasks[t.name] = t

    ns = {
        name: name 
        description: description
        tasks: tasks
    }

    return ns

module.exports.build-tasks = (v) ->
    ns = {}
    for i in v 
        ns[i.name] = i
    return ns

module.exports.task = ->
    a = arguments
    name = a[0] 
    description = ''
    fun = undefined 

    n = 1
    if _.is-string(a[n]) 
        description = a[n]
        n = n + 1

    if _.is-function(a[n])
        fun =  a[n] 
    else 
        throw "Sorry, #{a[n]} is not a function"

    ts =  {
        name: name 
        description: description
        fun: fun 
    }

    return ts