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
ut              = require('utf-8')
winston         = require('winston')
path            = require('path')

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

    # @dep = require('dep')

    get-base-config-path = ->

      does-exist = (f) ->
        x = shelljs.test('-e', path.resolve(f))
        return x

      res = 
        | does-exist './.sk-files/config.js' => path.resolve('./.sk-files/config.js')
        | does-exist './config.js' => path.resolve('./config.js')
        | does-exist process.env.HOME + '/.sk-files/config.js' => process.env.HOME + '/.sk-files/config.js'
        | _ => null

      return res

    inner-module = ->
      # Use `inner-module` to inject dependencies into `dep`
      # e.g. sinon.stub mod.inner-module().dep, 'method'.
      #
      # You can access `dep` method with plain `dep.method`
      # in functions defined below.
      return root
          
    iface = { 
      inner-module: inner-module
      get-base-config-path: get-base-config-path
    }
  
    return iface
 
module.exports = _module()