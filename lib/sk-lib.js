(function(){
  var _, moment, fs, color, ref$, spawn, kill, __q, sh, os, shelljs, cl, ut, ticks, level, debug, sendCommand, createConnection, registerMsgHandlers, et, rexec, ch, src, otm, cwd, setupTemporaryDirectory, removeTemporaryDirectory, conf, slice$ = [].slice;
  _ = require('underscore');
  _.str = require('underscore.string');
  moment = require('moment');
  fs = require('fs');
  color = require('ansi-color').set;
  ref$ = require('child_process'), spawn = ref$.spawn, kill = ref$.kill;
  __q = require('q');
  sh = require('shelljs');
  os = require('os');
  shelljs = sh;
  cl = require('clark');
  ut = require('utf-8');
  ticks = ['▁', '▂', '▃', '▄', '▅', '▆', '▇'];
  level = function(l){
    var k;
    return (function(){
      var i$, ref$, len$, results$ = [];
      for (i$ = 0, len$ = (ref$ = (fn$())).length; i$ < len$; ++i$) {
        k = ref$[i$];
        results$.push(ticks[k]);
      }
      return results$;
      function fn$(){
        var i$, to$, results$ = [];
        for (i$ = 0, to$ = l; i$ <= to$; ++i$) {
          results$.push(i$);
        }
        return results$;
      }
    }()).join('');
  };
  _.mixin(_.str.exports());
  _.str.include('Underscore.string', 'string');
  debug = false;
  sendCommand = function(conn, c, options){
    var d, output;
    d = __q.defer();
    if (debug) {
      console.log("[debug] Executing " + c);
    }
    output = "";
    conn.exec(c, function(err, stream){
      var readStdinCb;
      if (err) {
        d.reject("Exit code: " + err);
        return;
      }
      stream.on('data', function(it){
        output = output + it;
        if ((options != null ? options.silent : void 8) == null) {
          return process.stdout.write(it);
        }
      });
      readStdinCb = function(it){
        return stream.write(it);
      };
      process.stdin.resume();
      process.stdin.on('data', readStdinCb);
      return stream.on('exit', function(code, signal){
        if (code !== 0) {
          process.stdin.removeListener('data', readStdinCb);
          return d.reject("Exit code: " + code);
        } else {
          process.stdin.removeListener('data', readStdinCb);
          return d.resolve(output);
        }
      });
    });
    return d.promise;
  };
  createConnection = function(local){
    var __cnx, conn;
    __cnx = require('ssh2');
    conn = new __cnx();
    conn.connect({
      host: local.hostname,
      port: local.port,
      username: local.username,
      privateKey: require('fs').readFileSync(local.credentials)
    });
    return conn;
  };
  registerMsgHandlers = function(conn){
    conn.on('connect', function(){
      if (debug) {
        return console.log("[debug]", color("Connected", 'green'));
      }
    });
    conn.on('error', function(it){
      if (debug) {
        return console.log("[debug]", color(it, 'red'));
      }
    });
    return conn.on('close', function(){
      if (debug) {
        return console.log("[debug]", color("Closed", 'green'));
      }
    });
  };
  module.exports.run = function(local, command, options){
    var e, conn, shutdownOk, shutdownFail;
    e = __q.defer();
    conn = createConnection(local);
    registerMsgHandlers(conn);
    shutdownOk = function(it){
      conn.end();
      return e.resolve(it);
    };
    shutdownFail = function(it){
      conn.end();
      return e.reject(it);
    };
    conn.on('ready', function(){
      return sendCommand(conn, command, options).then(shutdownOk, shutdownFail);
    });
    return e.promise;
  };
  et = require('easy-table');
  module.exports.printAsTable = function(data, options){
    var i$, ref$, len$, f, j$, len1$, d, m, r;
    if ((options != null ? options.sparkly : void 8) != null && _.isArray(options.sparkly)) {
      for (i$ = 0, len$ = (ref$ = options.sparkly).length; i$ < len$; ++i$) {
        f = ref$[i$];
        if (f === 'percent') {
          for (j$ = 0, len1$ = data.length; j$ < len1$; ++j$) {
            d = data[j$];
            m = d['percent'] / 20;
            d['percent'] = _.rpad(level(m), 6) + "|" + _.pad(d['percent'], 3) + "%";
          }
        }
      }
    }
    if ((options != null ? options.remove : void 8) != null && _.isArray(options.remove)) {
      for (i$ = 0, len$ = (ref$ = options.remove).length; i$ < len$; ++i$) {
        r = ref$[i$];
        for (j$ = 0, len1$ = data.length; j$ < len1$; ++j$) {
          d = data[j$];
          delete d[r];
        }
      }
    }
    return console.log(et.printArray(data));
  };
  module.exports.get = function(local, remotePath, localPath){
    var e, conn, shutdownOk, shutdownFail;
    e = __q.defer();
    conn = createConnection(local);
    registerMsgHandlers(conn);
    shutdownOk = function(){
      conn.end();
      return e.resolve();
    };
    shutdownFail = function(it){
      conn.end();
      return e.reject(it);
    };
    conn.on('ready', function(){
      return conn.sftp(function(err, sftp){
        if (err) {
          return shutdownFail();
        } else {
          return sftp.fastGet(remotePath, localPath, function(err){
            if (err) {
              return shutdownFail();
            } else {
              return shutdownOk();
            }
          });
        }
      });
    });
    return e.promise;
  };
  module.exports.put = function(local, localPath, remotePath){
    var e, conn, shutdownOk, shutdownFail;
    e = __q.defer();
    conn = createConnection(local);
    registerMsgHandlers(conn);
    shutdownOk = function(){
      conn.end();
      return e.resolve();
    };
    shutdownFail = function(it){
      conn.end();
      return e.reject(it);
    };
    conn.on('ready', function(){
      return conn.sftp(function(err, sftp){
        if (err) {
          return shutdownFail();
        } else {
          return sftp.fastPut(localPath, remotePath, function(err){
            if (err) {
              return shutdownFail();
            } else {
              return shutdownOk();
            }
          });
        }
      });
    });
    return e.promise;
  };
  rexec = module.exports.run;
  ch = void 8;
  module.exports.createTunnel = function(address, through){
    var d, args;
    d = __q.defer();
    if (through == null) {
      console.log("Cannot create tunnel");
      d.reject("Cannot create tunnel");
    } else {
      args = ['-NL', address.use + ":" + address.hostname + ":" + address.port, through.username + "@" + through.hostname];
      console.log("ssh ", args[0], args[1], args[2]);
      ch = spawn('ssh', args);
      ch.on('error', function(){
        return d.reject("Failed connection");
      });
      ch.stderr.on('data', function(){
        return d.reject("Failed connection");
      });
      setTimeout(function(){
        return d.resolve();
      }, 500);
    }
    return d.promise;
  };
  module.exports.closeTunnel = function(){
    sh.exec("kill -9 " + ch.pid);
    ch = void 8;
    return true;
  };
  module.exports.namespace = function(){
    var a, name, description, tasks, n, i$, ref$, len$, t, ns;
    a = arguments;
    name = a[0];
    description = '';
    tasks = {};
    n = 1;
    if (_.isString(a[n])) {
      description = a[n];
      n = n + 1;
    }
    for (i$ = 0, len$ = (ref$ = slice$.call(a, n)).length; i$ < len$; ++i$) {
      t = ref$[i$];
      tasks[t.name] = t;
    }
    ns = {
      name: name,
      description: description,
      tasks: tasks
    };
    return ns;
  };
  module.exports.buildTasks = function(v){
    var ns, i$, len$, i;
    ns = {};
    for (i$ = 0, len$ = v.length; i$ < len$; ++i$) {
      i = v[i$];
      ns[i.name] = i;
    }
    return ns;
  };
  module.exports.task = function(){
    var a, name, description, fun, n, ts;
    a = arguments;
    name = a[0];
    description = '';
    fun = void 8;
    n = 1;
    if (_.isString(a[n])) {
      description = a[n];
      n = n + 1;
    }
    if (_.isFunction(a[n])) {
      fun = a[n];
    } else {
      throw "Sorry, " + a[n] + " is not a function";
    }
    ts = {
      name: name,
      description: description,
      fun: fun
    };
    return ts;
  };
  src = __dirname;
  otm = os.tmpdir != null ? os.tmpdir() : "/var/tmp";
  cwd = process.cwd();
  setupTemporaryDirectory = function(){
    var name, dire;
    name = "tmp_" + moment().format('HHmmss') + "_tmp";
    dire = otm + "/" + name;
    shelljs.mkdir('-p', dire);
    return dire;
  };
  removeTemporaryDirectory = function(dir){
    return shelljs.rm('-rf', dir);
  };
  conf = function(filename){
    return "input {\n  file {\n    type => \"syslog\"\n\n    # Wildcards work here :)\n    path => [ \"" + filename + "\" ]\n  }\n}\n\nfilter {\n  grok {\n    type => \"syslog\"\n    pattern => [ \"<%{POSINT:syslog_pri}>%{SPACE}%{GREEDYDATA:message_remainder}\" ]\n    add_tag => \"got_syslog_pri\"\n    add_field => [ \"syslog_raw_message\", \"%{@message}\" ]\n  }\n  syslog_pri {\n    type => \"syslog\"\n    tags => [ \"got_syslog_pri\" ]\n  }\n  mutate {\n    type => \"syslog\"\n    tags => [ \"got_syslog_pri\" ]\n    replace => [ \"@message\", \"%{message_remainder}\" ]\n  }\n  mutate {\n    type => \"syslog\"\n    tags => [ \"got_syslog_pri\" ]\n    remove => [ \"message_remainder\" ]\n  }\n \n  grok {\n    type => \"syslog\"\n    pattern => [ \"%{SYSLOGTIMESTAMP:syslog_timestamp}%{SPACE}%{GREEDYDATA:message_remainder}\" ]\n    add_tag => \"got_syslog_timestamp\"\n    add_field => [ \"received_at\", \"%{@timestamp}\" ]\n  }\n  mutate {\n    type => \"syslog\"\n    tags => [ \"got_syslog_timestamp\" ]\n    replace => [ \"@message\", \"%{message_remainder}\" ]\n  }\n  mutate {\n    type => \"syslog\"\n    tags => [ \"got_syslog_timestamp\" ]\n    remove => [ \"message_remainder\" ]\n  }\n  date {\n    type => \"syslog\"\n    tags => [ \"got_syslog_timestamp\" ]\n    syslog_timestamp => [ \"MMM  d HH:mm:ss\", \"MMM dd HH:mm:ss\", \"ISO8601\" ]\n  }\n \n  grok {\n    type => \"syslog\"\n    pattern => [ \"%{SYSLOGHOST:syslog_hostname}%{SPACE}%{GREEDYDATA:message_remainder}\" ]\n    add_tag => [ \"got_syslog_host\", \"%{syslog_hostname}\" ]\n    add_field => [ \"logstash_source\", \"%{@source_host}\" ]\n  }\n  mutate {\n    type => \"syslog\"\n    tags => [ \"got_syslog_host\" ]\n    replace => [ \"@source_host\", \"%{syslog_hostname}\" ]\n    replace => [ \"@message\", \"%{message_remainder}\" ]\n  }\n  mutate {\n    type => \"syslog\"\n    tags => [ \"got_syslog_host\" ]\n    remove => [ \"message_remainder\" ]\n  }\n}\n\noutput {\n    elasticsearch { embedded => true }\n}";
  };
  module.exports.runLsSyslog = function(filename){
    var tmp, command;
    tmp = setupTemporaryDirectory();
    console.log("Created " + tmp + "/log.conf");
    fs.writeFileSync(tmp + "/log.conf", conf(filename));
    command = "java -jar " + __dirname + "/logstash.jar agent -f " + tmp + "/log.conf -- web";
    console.log("Preparing Logstash/Elasticsearch at http://localhost:9292");
    return shelljs.exec(command);
  };
}).call(this);
