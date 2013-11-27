#!/usr/bin/env lsc
# options are accessed as argv.option

_       = require('underscore')
_.str   = require('underscore.string');
moment  = require 'moment'
fs      = require 'fs'
color   = require('ansi-color').set
os      = require('os')
shelljs = require('shelljs')
table   = require('ansi-color-table');


_.mixin(_.str.exports());
_.str.include('Underscore.string', 'string');

name        = "Swiss Knife 2.0 - Deploy Tool"
description = "A remote deploy tool inspired by the Inception Movie"
author      = "Vittorio Zaccaria"
year        = "2013"

src = __dirname
otm = if (os.tmpdir?) then os.tmpdir() else "/var/tmp"
cwd = process.cwd()

setup-temporary-directory = ->
    name = "tmp_#{moment().format('HHmmss')}_tmp"
    dire = "#{otm}/#{name}" 
    shelljs.mkdir '-p', dire
    return dire


usage-string = """

#{color(name, \bold)}. #{description}
(c) #author, #year

Usage: #{name} [--option=V | -o V] task(s) 
"""

require! 'optimist'

argv     = optimist.usage(usage-string,
              help:
                alias: 'h', description: 'This help'
              list:
                alias: 'l', description: 'List available tasks'
              default:
                alias: 'd', description: 'Use default node'
              command:
                alias: 'c', description: 'use with `cmd` task to specify a remote command'
              node:
                alias: 'n', description: 'Specify target node or a comma separated list (e.g., -n s1,s2,s3)'
                         ).boolean(\l)
                          .boolean(\d)
                          .argv

if(argv.help)
  optimist.showHelp()

{ nodes, namespace } = require './config'

tab = 25

nsf = (s) ->
  _.pad('', 2) + _.rpad(color(s, \bold), (tab-2))

tf = (s) ->
  _.pad(':', 10) + _.rpad(s, (tab-20+2))

# console.log JSON.stringify(nodes, null, 4)
# console.log argv

if argv.list? and argv.list or argv.help? and argv.help
  console.log "Namespace and tasklist:"
  console.log ""
  ns = namespace
  for nns, vns of ns
      console.log nsf(nns), " — #{vns.description}"
      for k,v of vns.tasks 
         console.log tf(k), " — #{v.description}"
      console.log ""

  console.log "Nodes:"    
  console.log ""
  for name, data of nodes
      if name isnt \default
        console.log nsf(name), " — ", data.description, "[", color(data.access, \green), "]" 
  return 0

if not nodes.default? or not nodes[nodes.default]? 
  console.log "You should specify a default node"
  return

__q = require('q')

invoke-actions = (p, tt) ->

  if not nodes[tt]?
    return p.then-reject("Skipping #tt, invalid target ")

  if argv._.length == 0
    return p.then-reject("Pleas specify at least one task")

  { create-tunnel, close-tunnel } = require('./sk-lib')

  target = nodes[tt]

  for t in argv._ 

    if t in _.pluck(namespace['general'].tasks, 'name')

      if not target.path.from?
        console.log "Launching `#t` on `#{target.path.hostname}`"
        task-function = namespace['general'].tasks[t].fun 
        context = { local: target.path, args:argv }
        p := p.then( -> task-function.apply(context))

      else
        address = target.path 
        through = nodes[target.path.from].path
        console.log "Launching `#t` on `#{address.hostname}:#{address.port}` through `#{through.hostname}`"
        task-function = namespace['general'].tasks[t].fun 

        new-context = 
          local: 
            username:    address.username
            hostname:    "localhost"
            port:        address.use
            credentials: address.credentials
          args:argv

        p := p.then( -> create-tunnel(address, through)) 
        p := p.then( -> task-function.apply(new-context))
        p := p.then( -> close-tunnel())

    else 
      return p.thenReject("Sorry, no valid task named #t")

  return p

ok = ->
  console.log color("Ok", \green)
  process.exit()

ko = ->
  console.log color("Error:", "red"), it
  process.exit()

original = __q.defer()
current = original.promise

if argv.default 
  if nodes.default?
    current = invoke-actions(current, nodes.default)
  else 
    current = current.thenReject("Please specify a default node")

for n in _.words(argv.node,',')
  current := invoke-actions(current, n)

current.then ok, ko
original.resolve()



# command = argv._

