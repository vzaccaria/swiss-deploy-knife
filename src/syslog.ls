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

disp-ok = -> winston.info "Ok"
disp-ko = -> 
  winston.error it.toString()
disp    = winston.info
pdisp   = console.log
pdeb    = winston.warn

_.mixin(_.str.exports());
_.str.include('Underscore.string', 'string');


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



_module = ->

    var scope 
  
    init = (data) -> 
       scope := data


    run-ls-syslog = (filename) ->

        tmp = setup-temporary-directory()
        disp "Created #tmp/log.conf"
        fs.write-file-sync "#tmp/log.conf", conf(filename)
        command = "java -jar #{__dirname}/logstash.jar agent -f #tmp/log.conf -- web"
        disp "Preparing Logstash/Elasticsearch at http://localhost:9292"
        shelljs.exec command 
            # remove-temporary-directory(dir)

    iface = { 
      run-ls-syslog: run-ls-syslog
    }
  
    return iface
 
module.exports = _module()