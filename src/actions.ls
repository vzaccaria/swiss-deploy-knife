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

    @tunnel = require('./tunnel')

    inner-module = ->
      return root

    print = ->
      pdisp this

    decompose-task = (tval) ->
       [tns, t] = tval / ':'
       if not t? 
            t   := tns 
            tns := 'general'
       return [tns, t]    
          

    direct-call = (p, tns, t, target-node, argv, namespace, nodes) ->

              if not nodes?
                return p.then-reject("Invalid nodes specified")

              if not target-node?.path?.hostname?
                return p.then-reject("Invalid node specified")  

              if not namespace?[tns]?.tasks?[t]?.fun?
                return p.then-reject("Invalid task function.")

              disp "Launching `#tns:#t` on `#{target-node.path.hostname}`"

              task-function = namespace[tns].tasks[t].fun 
 
              context = 
                remote:     target-node.path
                args:       argv 
                tasks:      namespace[tns].tasks
                nodes:      nodes

              p = p.then( -> task-function.apply(context))      
              return p

    indirect-call = (p, tns, t, target-node, argv, namespace, nodes) ->

              if not nodes?
                return p.then-reject("Invalid nodes specified")

              if not target-node?.path?.hostname? or 
                 not target-node?.path?.from? or 
                 not target-node?.path?.use?
                return p.then-reject("Invalid node specified")  

              if not namespace?[tns]?.tasks?[t]?.fun?
                return p.then-reject("Invalid task function.")

              { address, through } = tunnel.decompose-address(target-node, nodes) 

              disp "Launching `#tns:#t` on `#{address.hostname}:#{address.port}` through `#{through.hostname}`"
              p = tunnel.mount-tunnel(target-node, p, argv.latency, nodes)

              context = 
                remote: 
                  username:    address.username
                  hostname:    "localhost"
                  port:        address.use
                  credentials: address.credentials
                  access:      address.access 

                tasks:      namespace[tns].tasks

                nodes:      nodes

                args:
                  argv

              task-function = namespace[tns].tasks[t].fun 

              if not task-function?
                return p.then-reject("The function does not exist.")

              p = p.then ( -> task-function.apply(context))
              return tunnel.unmount-tunnel(target-node, p)

    invoke-actions = (p, tt, argv, nodes, namespace) ->

        if not nodes?[tt]?
          return p.then-reject("Skipping #tt, invalid target-node ")

        if argv._.length == 0
          return p.then-reject("Pleas specify at least one task")

        target-node = nodes[tt]

        for tval in argv._ 

          [tns, t] = decompose-task(tval)

          if not namespace[tns]?
              return p.then-reject("Please specify a valid namespace")

          if t in _.pluck(namespace[tns].tasks, 'name')
            if not target-node.path.from?
                p = direct-call(p, tns, t, target-node, argv, namespace, nodes)
            else
                p = indirect-call(p, tns, t, target-node, argv, namespace, nodes)
          else 
            return p.thenReject("Sorry, no valid task named #t")
        return p

    iface = {
        print:  print
        invoke-actions : invoke-actions
        inner-module   : inner-module 
        direct-call    : direct-call
        indirect-call  : indirect-call
    }
  
    return iface
 
module.exports = _module()