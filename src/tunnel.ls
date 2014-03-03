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
{additional-ssh-parameters} = require('./ssh')

disp-ok = -> winston.info "Ok"
disp-ko = -> 
  winston.error it.toString()
disp    = winston.info
pdisp   = console.log
pdeb    = winston.warn

_.mixin(_.str.exports());
_.str.include('Underscore.string', 'string');



_module = ->

    var scope 
  
    init = (data) -> 
       scope := data

    ch = undefined

    create-tunnel = (address, through) ->
        d = __q.defer()
        if not through?
            disp-ko "Cannot create tunnel"
            d.reject("Cannot create tunnel")
        else 
            args = [ 
                        '-NL' 
                        "#{address.use}:#{address.hostname}:#{address.port}"
                        "#{through.username}@#{through.hostname}" 

                        ]
          
            if through.port != 22
              args = args ++ [ "-p", "#{through.port}" ]
            args = args ++ additional-ssh-parameters

            command = [a for a in args] * " "
            pdeb "Executing command `ssh #{command}`"

            ch := spawn 'ssh', args

            pdeb "Command has pid: #{ch.pid}"
            
            ch.on 'error', -> 
                d.reject("Failed connection")

            ch.stderr.on 'data', ->
                d.reject("Failed connection")

            set-timeout (-> d.resolve()), 500

        return d.promise

    close-tunnel = ->
       sh.exec("kill -9 #{ch.pid}")
       ch := undefined
       return true

    decompose-address = (target, nodes) ->
      return { address: target.path, through: nodes[target.path.from].path }

    mount-tunnel = (target, p, latency, nodes) ->
      { address, through } = decompose-address(target, nodes) 
      p := p.then( -> create-tunnel(address, through)) 
      if latency? 
        disp "Using latency #{latency}"
        p := p.then( -> __q.delay(latency))
      return p;

    unmount-tunnel = (target, p) ->
      p := p.then( (-> close-tunnel()), (-> close-tunnel(); throw it;) )
      return p;

     
    iface = { 
        mount-tunnel: mount-tunnel 
        unmount-tunnel: unmount-tunnel
        decompose-address: decompose-address
    }
  
    return iface
 
module.exports = _module()