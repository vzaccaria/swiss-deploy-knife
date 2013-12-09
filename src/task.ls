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

disp-ok = -> 
  winston.info "Ok"
  
disp-ko = -> 
  winston.error it.toString()
  
disp    = winston.info
pdisp   = console.log
pdeb    = winston.warn

_.mixin(_.str.exports());
_.str.include('Underscore.string', 'string');

_module = ->

    @connect = require('./connect')

    inner-module = ->
      # Use `inner-module` to inject dependencies into `dep`
      # e.g. sinon.stub mod.inner-module().dep, 'method'.
      #
      # You can access `dep` method with plain `dep.method`
      # in functions defined below.
      return root

    sequence = (context, args) ->

        if _.is-array(args)
            od = __q.defer()
            td = od.promise 

            for tt in args 
                let t = tt
                    td := td.then -> 
                        context.tasks[t].fun.apply(context)

            od.resolve(0)
            return td
        else
            od = __q.defer()
            td = od.promise
            td = td.then -> 
                let t=args
                    context.tasks[t].fun.apply(context)
            od.resolve(0)
            return td

    namespace = ->
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

    build-tasks = (v) ->
      ns = {}
      for i in v 
          ns[i.name] = i
      return ns

    task = ->
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

    get-interested-nodes = (argv, nodes) ->
        if argv.default or not argv.node
          if nodes.default?
            return [ nodes.default ]
          else 
            return []
        else 
          return _.words(argv.node,',')

    bsh = (cmd) ->
        return "bash -l -c '#cmd'"
        return iface

    run = (local, command, options) ->

        e = __q.defer()
        pdeb "Entering `run`"
        conn = connect.create-connection()
        conn = connect.connect(conn, local)
        pdeb "Executing `run`"
        connect.register-msg-handlers(conn, e)

        shutdown-ok = -> 
                conn.end()
                e.resolve(it)

        shutdown-fail = ->
                conn.end()
                e.reject(it)      

        conn.on 'ready', -> 
           pdeb "Ready to send command #command"
           if _.is-array(command)
                od = __q.defer()
                td = od.promise

                for c in command 
                    let cc=c
                        td := td.then -> 
                            pdeb "Sending command #cc"
                            connect.send-command(conn, cc)

                td.then(shutdown-ok, shutdown-fail)
                od.resolve(0)
           else 
                connect.send-command(conn, command, options).then(shutdown-ok, shutdown-fail)

        return e.promise

    iface = { 
        inner-module         : inner-module
        sequence             : sequence
        namespace            : namespace
        build-tasks          : build-tasks
        bsh                  : bsh
        run                  : run
        task                 : task
        get-interested-nodes : get-interested-nodes

    }

    return iface
 
module.exports = _module()