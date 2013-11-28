#!/usr/bin/env lsc
# options are accessed as argv.option

_      = require('underscore')
_.str  = require('underscore.string');
moment = require 'moment'
fs     = require 'fs'
color  = require('ansi-color').set
os      = require('os')
shelljs = require('shelljs')
table = require('ansi-color-table')

_.mixin(_.str.exports());
_.str.include('Underscore.string', 'string');

name        = "ParseAuthJSON"
description = "As the name implies"
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

Usage: #{name} [--option=V | -o V] 
"""

require! 'optimist'

argv     = optimist.usage(usage-string,
              file:
                alias: 'f', description: 'File name', boolean: true

              help:
                alias: 'h', description: 'this help'

                         ).boolean(\h).argv


if(argv.help)
  optimist.showHelp()
  return

command = argv._

##### Parse rules

tokens = {
  month: "\\w\\w\\w"
  day:   "\\d\\d"
  time:  "\\d\\d:\\d\\d:\\d\\d"
}


rules = [
  -> "#{@month()} #{@day()} #{@time()} hbomb CRON" 
  ]

regex = (m, cc) ->
  ff = {}

  for k,v of m 
    let vv=v
      ff[k] = -> vv

  return new RegExp(cc.apply(ff))

pos = (m, cc) ->
  ff = {}
  mm = {}
  pos = 0
  for k,v of m 
    let vv=v
      ff[k] = ~>
        mm[k] = pos
        pos := pos+1
        return pos
  console.log cc.apply(ff)
  console.log mm

# pos(matchers, rules[0])


#####


test-str = """
Nov 25 15:17:01 hbomb CRON[10799]: pam_unix(cron:session): session closed for user root
Nov 25 15:25:01 hbomb CRON[10805]: pam_unix(cron:session): session opened for user root by (uid=0)
Nov 25 15:25:01 hbomb CRON[10805]: pam_unix(cron:session): session closed for user root
"""

for l in _.lines(test-str)
  r = regex(tokens, rules[0])
  if r.exec(l)
    console.log "#l matches !"




