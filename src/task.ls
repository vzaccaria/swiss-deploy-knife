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

        opt = {}
        if _.is-object(a[n]) and not (a[n].fun? or a[n].description? or a[n].name)
            opt = a[n]
            n = n + 1

        for t in a[n to ]
            tasks[t.name] = t

        ns = {
            name: name 
            description: description
            tasks: tasks
        }

        _.extend(ns, opt)

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

        show = false

        if a[n]?.show? 
            show := a[n].show
            n = n + 1


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
            show: show
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
        "bash -l -c '#cmd'"

    zsh = (c) ->
        "zsh -l -c '#c'"

    create-local = (remote-node, options) ->
        if remote-node.login?.directory?
            cm = "mkdir -p #{remote-node.login.directory}"
            cm = 
                | remote-node.login?.run-as-sudo? and (remote-node.login.run-as-sudo == true) => "sudo #cm"
                | options?.run-as-sudo? and (options?.run-as-sudo == true) => "sudo #cm"
                | _ => cm

            return run(remote-node, cm)

    remove-local = (remote-node, options) ->
        if remote-node.login?.directory?
            cm = "rm -rf #{remote-node.login.directory}"
            cm = 
                | remote-node.login?.run-as-sudo? and (remote-node.login.run-as-sudo == true) => "sudo #cm"
                | options?.run-as-sudo? and (options?.run-as-sudo == true) => "sudo #cm"
                | _ => cm 

            return run(remote-node, cm)

    run-local = (remote-node, comms, options) ->
        var cm
        var cd
        new-commands = []
        sending-commands = []

        # console.log "1)", JSON.stringify(comms, null, 4)

        if _.is-string comms
            sending-commands.push comms 
        else 
            sending-commands = comms

        # console.log "2)", JSON.stringify(sending-commands, null, 4)

        for command in sending-commands

            cm = 
                | remote-node.login?.run-as-sudo? and (remote-node.login.run-as-sudo == true) => "sudo #command"
                | options?.run-as-sudo? and (options?.run-as-sudo == true) => "sudo #command"
                | _ => command

            cd := 
                | remote-node.login?.directory? and options?.sub-dir? => "cd #{remote-node.login.directory}/#{options.sub-dir} && #cm"
                | remote-node.login?.directory? => "cd #{remote-node.login.directory} && #cm" 
                | _ => cm

            # console.log "3)", JSON.stringify(cd, null, 4)

            if remote-node.login?.shell? && _.is-function(remote-node.login.shell)
                cd := remote-node.login.shell cd

            # console.log "4)", JSON.stringify(cd, null, 4)

            new-commands := new-commands ++ [ cd ]    

        # console.log new-commands
        return run(remote-node, new-commands, options)


    run = (remote-node, command, options) ->

        e = __q.defer()
        pdeb "Entering `run`"
        conn = connect.create-connection()
        conn = connect.connect(conn, remote-node)
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
        run-local            : run-local
        task                 : task
        get-interested-nodes : get-interested-nodes
        create-local         : create-local
        remove-local         : remove-local
        zsh                  : zsh

    }

    return iface
 
module.exports = _module()