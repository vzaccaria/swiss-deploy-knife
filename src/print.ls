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
et              = require('easy-table')

disp-ok = -> winston.info "Ok"
disp-ko = winston.error
disp    = winston.info
pdisp   = console.log
pdeb    = winston.warn


_.mixin(_.str.exports());
_.str.include('Underscore.string', 'string');

# U+2581 ... U+2587
ticks = ['▁', '▂', '▃', '▄', '▅', '▆', '▇']

circ = ['◯ ','⚪ ', '⚬ ', '● ']

circles = (l) ->
    one-gb = 2^30
    hundred-gb = Math.floor(l/(100*one-gb))
    l = l - hundred-gb*100*one-gb
    tens-gb = Math.floor(l/(10*one-gb))
    l = l - tens-gb*10*one-gb
    unit-gb = Math.floor(l/one-gb)
    a = [ circ[0] for k in [1 to hundred-gb] ] * ''
    b = [ circ[1] for k in [1 to tens-gb] ] * ''
    return a+b

level = (l) ->
    [ ticks[k] for k in [0 to l] ] * ''


_module = ->

    var scope 
  
    init = (data) -> 
       scope := data

    tab = 40

    format-task-namespace = (s) ->
      _.pad('', 2) + _.rpad(color(s, \bold), (tab-2))

    format-task-name = (ns, s) ->
      _.pad("#ns:", 10) + _.rpad(s, (tab-20+2))

    print-env = (nodes, namespace) ->
      pdisp "Namespace and tasklist:"
      pdisp ""
      for nns, vns of namespace
          pdisp format-task-namespace(nns), " — #{vns.description}"
          for k,v of vns.tasks 
             pdisp format-task-name(nns, k), " — #{v.description}"
          pdisp ""

      pdisp "Nodes:"    
      pdisp ""
      for name, data of nodes
          if name isnt \default
            pdisp format-task-namespace(name), " — ", data.description, "[", color(data.path.access, \green), "]" 
      return 0


    print-as-table = (local, data, options) ->
        if options?.sparkly? and _.is-array(options.sparkly)
            for f in options.sparkly 
                if f is 'percent'
                    for d in data 
                        m = d['percent']/20
                        d['percent'] = _.rpad(level(m),7) + "|" + _.pad(d['percent'], 3) + "%"

                if f is 'blocks'
                    for d in data 
                        if local.hosttype == 'linux'
                            f=1
                        else 
                            f=2
                        bytes = d['blocks']*1000/f
                        d['blocks'] = _.rpad(circles(bytes),24) + "|"


        if options?.remove? and _.is-array(options.remove)
            for r in options.remove 
                for d in data
                    delete d[r]
        
        pdisp et.print-array(data)
  
    iface = { 
      print-as-table: print-as-table
      print-env: print-env
    }
  
    return iface
 
module.exports = _module()