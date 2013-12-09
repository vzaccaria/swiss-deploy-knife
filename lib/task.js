(function(){
  var _, moment, fs, color, ref$, spawn, kill, __q, sh, os, shelljs, cl, ut, winston, dispOk, dispKo, disp, pdisp, pdeb, _module, slice$ = [].slice;
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
  winston = require('winston');
  dispOk = function(){
    return winston.info("Ok");
  };
  dispKo = function(it){
    return winston.error(it.toString());
  };
  disp = winston.info;
  pdisp = console.log;
  pdeb = winston.warn;
  _.mixin(_.str.exports());
  _.str.include('Underscore.string', 'string');
  _module = function(){
    var innerModule, sequence, namespace, buildTasks, task, getInterestedNodes, bsh, run, iface;
    this.connect = require('./connect');
    innerModule = function(){
      return root;
    };
    sequence = function(context, args){
      var od, td, i$, len$, tt;
      if (_.isArray(args)) {
        od = __q.defer();
        td = od.promise;
        for (i$ = 0, len$ = args.length; i$ < len$; ++i$) {
          tt = args[i$];
          (fn$.call(this, tt, tt));
        }
        od.resolve(0);
        return td;
      } else {
        od = __q.defer();
        td = od.promise;
        td = td.then(function(){
          return (function(t){
            return context.tasks[t].fun.apply(context);
          }.call(this, args));
        });
        od.resolve(0);
        return td;
      }
      function fn$(t, tt){
        td = td.then(function(){
          return context.tasks[t].fun.apply(context);
        });
      }
    };
    namespace = function(){
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
    buildTasks = function(v){
      var ns, i$, len$, i;
      ns = {};
      for (i$ = 0, len$ = v.length; i$ < len$; ++i$) {
        i = v[i$];
        ns[i.name] = i;
      }
      return ns;
    };
    task = function(){
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
    getInterestedNodes = function(argv, nodes){
      if (argv['default'] || !argv.node) {
        if (nodes['default'] != null) {
          return [nodes['default']];
        } else {
          return [];
        }
      } else {
        return _.words(argv.node, ',');
      }
    };
    bsh = function(cmd){
      return "bash -l -c '" + cmd + "'";
      return iface;
    };
    run = function(local, command, options){
      var e, conn, shutdownOk, shutdownFail;
      e = __q.defer();
      pdeb("Entering `run`");
      conn = connect.createConnection();
      conn = connect.connect(conn, local);
      pdeb("Executing `run`");
      connect.registerMsgHandlers(conn, e);
      shutdownOk = function(it){
        conn.end();
        return e.resolve(it);
      };
      shutdownFail = function(it){
        conn.end();
        return e.reject(it);
      };
      conn.on('ready', function(){
        var od, td, i$, ref$, len$, c;
        pdeb("Ready to send command " + command);
        if (_.isArray(command)) {
          od = __q.defer();
          td = od.promise;
          for (i$ = 0, len$ = (ref$ = command).length; i$ < len$; ++i$) {
            c = ref$[i$];
            (fn$.call(this, c, c));
          }
          td.then(shutdownOk, shutdownFail);
          return od.resolve(0);
        } else {
          return connect.sendCommand(conn, command, options).then(shutdownOk, shutdownFail);
        }
        function fn$(cc, c){
          td = td.then(function(){
            pdeb("Sending command " + cc);
            return connect.sendCommand(conn, cc);
          });
        }
      });
      return e.promise;
    };
    iface = {
      innerModule: innerModule,
      sequence: sequence,
      namespace: namespace,
      buildTasks: buildTasks,
      bsh: bsh,
      run: run,
      task: task,
      getInterestedNodes: getInterestedNodes
    };
    return iface;
  };
  module.exports = _module();
}).call(this);
