(function(){
  var _, moment, fs, color, ref$, spawn, kill, __q, sh, debug, sendCommand, rexec, ch, slice$ = [].slice;
  _ = require('underscore');
  _.str = require('underscore.string');
  moment = require('moment');
  fs = require('fs');
  color = require('ansi-color').set;
  ref$ = require('child_process'), spawn = ref$.spawn, kill = ref$.kill;
  __q = require('q');
  sh = require('shelljs');
  _.mixin(_.str.exports());
  _.str.include('Underscore.string', 'string');
  debug = false;
  sendCommand = function(conn, c){
    var d;
    d = __q.defer();
    if (debug) {
      console.log("[debug] Executing " + c);
    }
    conn.exec(c, function(err, stream){
      if (err) {
        d.reject("Exit code: " + err);
        return;
      }
      stream.on('data', function(it){
        var i$, ref$, len$, l, results$ = [];
        for (i$ = 0, len$ = (ref$ = _.lines(it.toString())).length; i$ < len$; ++i$) {
          l = ref$[i$];
          results$.push(console.log(l));
        }
        return results$;
      });
      return stream.on('exit', function(code, signal){
        if (code !== 0) {
          return d.reject("Exit code: " + code);
        } else {
          return d.resolve("Exit code: " + code);
        }
      });
    });
    return d.promise;
  };
  module.exports.run = function(local, command){
    var e, __cnx, conn, shutdownOk, shutdownFail;
    e = __q.defer();
    __cnx = require('ssh2');
    conn = new __cnx();
    conn.connect({
      host: local.hostname,
      port: local.port,
      username: local.username,
      privateKey: require('fs').readFileSync(local.credentials)
    });
    shutdownOk = function(){
      conn.end();
      return e.resolve();
    };
    shutdownFail = function(it){
      conn.end();
      return e.reject(it);
    };
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
    conn.on('close', function(){
      if (debug) {
        return console.log("[debug]", color("Closed", 'green'));
      }
    });
    conn.on('ready', function(){
      return sendCommand(conn, command).then(shutdownOk, shutdownFail);
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
}).call(this);
