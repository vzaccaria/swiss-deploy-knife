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

# U+2581 ... U+2587
ticks = ['▁', '▂', '▃', '▄', '▅', '▆', '▇']

level = (l) ->
    [ ticks[k] for k in [0 to l] ] * ''

_.mixin(_.str.exports());
_.str.include('Underscore.string', 'string');

debug = false

send-command = (conn, c, options) ->
  d = __q.defer()
  if debug then console.log "[debug] Executing #c"

  output = ""

  conn.exec c, (err, stream) ->
      if err then 
        d.reject("Exit code: #err")
        return

      stream.on 'data', -> 
            output := output + it
            if not options?.silent?
                process.stdout.write it

      read-stdin-cb = ->
            stream.write it 

      process.stdin.resume()
      process.stdin.on 'data', read-stdin-cb

      stream.on 'exit', (code, signal) -> 
        if code isnt 0
          process.stdin.remove-listener 'data', read-stdin-cb
          d.reject("Exit code: #code")        
        else
          process.stdin.remove-listener 'data', read-stdin-cb
          d.resolve(output)

  return d.promise



create-connection = (local) ->
    __cnx = require('ssh2')
    conn   = new __cnx()
    conn.connect {
        host:           local.hostname
        port:           local.port 
        username:       local.username
        private-key:    require('fs').readFileSync(local.credentials)
    }
    return conn

register-msg-handlers = (conn) ->
    conn.on 'connect',  -> if debug then console.log "[debug]", color("Connected", \green)
    conn.on 'error',    -> if debug then console.log "[debug]", color(it, \red)
    conn.on 'close',    -> if debug then console.log "[debug]", color("Closed", \green)

module.exports.run = (local, command, options) ->

    e = __q.defer()
    conn = create-connection(local)
    register-msg-handlers(conn)

    shutdown-ok = -> 
            conn.end()
            e.resolve(it)

    shutdown-fail = ->
            conn.end()
            e.reject(it)      


    conn.on 'ready',    -> 
        send-command(conn, command, options).then(shutdown-ok, shutdown-fail)

    return e.promise

et = require('easy-table')

module.exports.print-as-table = (data, options) ->
    if options?.sparkly? and _.is-array(options.sparkly)
        for f in options.sparkly 
            if f is 'percent'
                for d in data 
                    m = d['percent']/20
                    d['percent'] = _.rpad(level(m),6) + "|" + _.pad(d['percent'], 3) + "%"


    if options?.remove? and _.is-array(options.remove)
        for r in options.remove 
            for d in data
                delete d[r]
        
    console.log et.print-array(data)

module.exports.get = (local, remote-path, local-path) ->

    e = __q.defer()
    conn = create-connection(local)
    register-msg-handlers(conn)

    shutdown-ok = -> 
            conn.end()
            e.resolve()

    shutdown-fail = ->
            conn.end()
            e.reject(it)      


    conn.on 'ready', -> 
        conn.sftp (err, sftp) ->
            if err 
                shutdown-fail()
            else 
                sftp.fast-get remote-path, local-path, (err) ->
                    if err 
                        shutdown-fail()
                    else 
                        shutdown-ok()

    return e.promise



module.exports.put = (local, local-path, remote-path) ->

    e = __q.defer()
    conn = create-connection(local)
    register-msg-handlers(conn)

    shutdown-ok = -> 
            conn.end()
            e.resolve()

    shutdown-fail = ->
            conn.end()
            e.reject(it)      


    conn.on 'ready', -> 
        conn.sftp (err, sftp) ->
            if err 
                shutdown-fail()
            else 
                sftp.fast-put local-path, remote-path, (err) ->
                    if err 
                        shutdown-fail()
                    else 
                        shutdown-ok()

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

src = __dirname
otm = if (os.tmpdir?) then os.tmpdir() else "/var/tmp"
cwd = process.cwd()

setup-temporary-directory = ->
    name = "tmp_#{moment().format('HHmmss')}_tmp"
    dire = "#{otm}/#{name}" 
    shelljs.mkdir '-p', dire
    return dire


remove-temporary-directory = (dir) ->
    shelljs.rm '-rf', dir 

conf = (filename) ->
    """
input {
  file {
    type => "syslog"

    # Wildcards work here :)
    path => [ "#filename" ]
  }
}

filter {
  grok {
    type => "syslog"
    pattern => [ "<%{POSINT:syslog_pri}>%{SPACE}%{GREEDYDATA:message_remainder}" ]
    add_tag => "got_syslog_pri"
    add_field => [ "syslog_raw_message", "%{@message}" ]
  }
  syslog_pri {
    type => "syslog"
    tags => [ "got_syslog_pri" ]
  }
  mutate {
    type => "syslog"
    tags => [ "got_syslog_pri" ]
    replace => [ "@message", "%{message_remainder}" ]
  }
  mutate {
    type => "syslog"
    tags => [ "got_syslog_pri" ]
    remove => [ "message_remainder" ]
  }
 
  grok {
    type => "syslog"
    pattern => [ "%{SYSLOGTIMESTAMP:syslog_timestamp}%{SPACE}%{GREEDYDATA:message_remainder}" ]
    add_tag => "got_syslog_timestamp"
    add_field => [ "received_at", "%{@timestamp}" ]
  }
  mutate {
    type => "syslog"
    tags => [ "got_syslog_timestamp" ]
    replace => [ "@message", "%{message_remainder}" ]
  }
  mutate {
    type => "syslog"
    tags => [ "got_syslog_timestamp" ]
    remove => [ "message_remainder" ]
  }
  date {
    type => "syslog"
    tags => [ "got_syslog_timestamp" ]
    syslog_timestamp => [ "MMM  d HH:mm:ss", "MMM dd HH:mm:ss", "ISO8601" ]
  }
 
  grok {
    type => "syslog"
    pattern => [ "%{SYSLOGHOST:syslog_hostname}%{SPACE}%{GREEDYDATA:message_remainder}" ]
    add_tag => [ "got_syslog_host", "%{syslog_hostname}" ]
    add_field => [ "logstash_source", "%{@source_host}" ]
  }
  mutate {
    type => "syslog"
    tags => [ "got_syslog_host" ]
    replace => [ "@source_host", "%{syslog_hostname}" ]
    replace => [ "@message", "%{message_remainder}" ]
  }
  mutate {
    type => "syslog"
    tags => [ "got_syslog_host" ]
    remove => [ "message_remainder" ]
  }
}

output {
    elasticsearch { embedded => true }
}
    """    

module.exports.run-ls-syslog = (filename) ->

    tmp = setup-temporary-directory()
    console.log "Created #tmp/log.conf"
    fs.write-file-sync "#tmp/log.conf", conf(filename)
    command = "java -jar #{__dirname}/logstash.jar agent -f #tmp/log.conf -- web"
    console.log "Preparing Logstash/Elasticsearch at http://localhost:9292"
    shelljs.exec command 
        # remove-temporary-directory(dir)





