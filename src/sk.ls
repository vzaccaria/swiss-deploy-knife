#!/usr/bin/env lsc
# options are accessed as argv.option

_                                = require('underscore')
_.str                            = require('underscore.string');
moment                           = require 'moment'
fs                               = require 'fs'
color                            = require('ansi-color').set
os                               = require('os')
shelljs                          = require('shelljs')
table                            = require('ansi-color-table');
__q                              = require('q')
winston                          = require('winston')
{ invoke-actions }               = require('../lib/actions')
{ mount-tunnel, unmount-tunnel } = require('../lib/tunnel')
{ print-env }                    = require('../lib/print')
{ get-interested-nodes }         = require('../lib/task')
{ get-base-config-path }         = require('../lib/config-search')

disp-ok = -> winston.info "Ok"
disp-ko = -> 
  winston.error it.toString()

disp    = winston.info
pdisp   = console.log
pdeb    = winston.warn

psetup = (file) ->
    if file?
        winston.add(winston.transports.File, { filename: file });
        winston.remove(winston.transports.Console);
    else
        winston.remove(winston.transports.Console);
        # winston.add(winston.transports.Console, { level: 'error', +colorize })
        winston.add(winston.transports.Console, { level: 'info', +colorize })


_.mixin(_.str.exports());
_.str.include('Underscore.string', 'string');

name        = "Swiss Knife 2.0 - Deploy Tool"
description = "A remote deploy tool inspired by the Inception Movie"
author      = "Vittorio Zaccaria"
year        = "2013"

src = __dirname
otm = if (os.tmpdir?) then os.tmpdir() else "/var/tmp"
cwd = process.cwd()

usage-string = """

#{color(name, \bold)}. #{description}
(c) #author, #year

Usage: #{name} [--option=V | -o V] task(s) 
"""

require! 'optimist'

argv     = optimist.usage(usage-string,
              help:
                alias: 'h', description: 'This help'
              logfile: 
                alias: 'g', description: 'Specify a log file'
              list:
                alias: 'l', description: 'List available tasks'
              default:
                alias: 'd', description: 'Use default node'
              command:
                alias: 'c', description: 'Use with `cmd` task to specify a remote command'
              file:
                alias: 'f', description: 'Use this config file'
              latency:
                alias: 'y', description: 'Wait for latency (ms)'
              namespace:
                alias: 's', description: 'Namespace for tasks', default: 'general'
              node:
                alias: 'n', description: 'Specify target node or a comma separated list (e.g., -n s1,s2,s3)'
              tags:
                alias: 't', description: 'Specify a tag list separated by commas'
              aliases:
                alias: 'z', description: 'dumps aliases for zsh, needs a -s'
                         ).boolean(\l)
                          .boolean(\d)
                          .boolean(\z)
                          .argv

if(argv.help)
  optimist.showHelp()

if not argv.file?
  argv.file = get-base-config-path()
  if not argv.file?
    disp-ko "Sorry, no configuration file found: #e"
    process.exit(0)    

psetup(argv.logfile)

disp("Using file: #{argv.file}")

ff = require("path").resolve(cwd, argv.file)
# disp "Using configuration file: #ff"

try 
  { nodes, namespace } = require(ff)
catch e
  disp-ko "Sorry, no configuration file found: #e"
  process.exit(0)
  
if argv.aliases? and argv.aliases
  # if not argv.namespace? or not namespace[argv.namespace]?
  #     disp-ko "Please, specify a namespace"
  # else
  #   if argv.namespace?
  #     ns = argv.namespace
  #     for n,v of namespace[ns].tasks
  #        console.log "alias #{ns}-#{n}='sk -f #{argv.file} -s #ns #n'"
  #   else 
      for ns, value of namespace 
         for n,v of namespace[ns].tasks
             console.log "alias #{ns}-#{n}='sk -f #{argv.file} -s #ns #n'"          

      process.exit(0)

if argv.list? and argv.list or argv.help? and argv.help
  print-env(nodes, namespace)

  hn = require('os').hostname()
  us = process.env.LOGNAME

  pdisp ""
  pdisp "To enable sk access to a remote machine, enable key auth:"
  pdisp " "
  pdisp " remote-prompt> ssh #us@#hn 'cat .ssh/id_rsa.pub' >> ~/.ssh/authorized_keys"
  pdisp ""

if not nodes.default? or not nodes[nodes.default]? 
  disp-ko "You should specify a default node"
  process.exit(0)

ok = ->
  disp-ok it
  process.exit()

ko = ->
  disp-ko it
  process.exit()

copy = (x) ->
  cmm = "echo '#x' | pbcopy"
  shelljs.exec(cmm)


original = __q.defer()
current = original.promise

for n in get-interested-nodes(argv, nodes)
  current = invoke-actions(current, n, argv, nodes, namespace)

current.then ok, ko
original.resolve()





# command = argv._

