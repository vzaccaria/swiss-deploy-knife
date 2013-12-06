(function(){
  var _, moment, fs, color, ref$, spawn, kill, __q, sh, os, shelljs, cl, ut, winston, dispOk, dispKo, disp, pdisp, pdeb, _module, split$ = ''.split;
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
    var innerModule, print, decomposeTask, directCall, indirectCall, invokeActions, iface;
    this.tunnel = require('./tunnel');
    innerModule = function(){
      return root;
    };
    print = function(){
      return pdisp(this);
    };
    decomposeTask = function(tval){
      var ref$, tns, t;
      ref$ = split$.call(tval, ':'), tns = ref$[0], t = ref$[1];
      if (t == null) {
        t = tns;
        tns = 'general';
      }
      return [tns, t];
    };
    directCall = function(p, tns, t, targetNode, argv, namespace, nodes){
      var ref$, ref1$, taskFunction, context;
      if (nodes == null) {
        return p.thenReject("Invalid nodes specified");
      }
      if ((targetNode != null ? (ref$ = targetNode.path) != null ? ref$.hostname : void 8 : void 8) == null) {
        return p.thenReject("Invalid node specified");
      }
      if ((namespace != null ? (ref$ = namespace[tns]) != null ? (ref1$ = ref$.tasks) != null ? (ref$ = ref1$[t]) != null ? ref$.fun : void 8 : void 8 : void 8 : void 8) == null) {
        return p.thenReject("Invalid task function.");
      }
      disp("Launching `" + tns + ":" + t + "` on `" + targetNode.path.hostname + "`");
      taskFunction = namespace[tns].tasks[t].fun;
      context = {
        remote: targetNode.path,
        args: argv,
        tasks: namespace[tns].tasks,
        nodes: nodes
      };
      p = p.then(function(){
        return taskFunction.apply(context);
      });
      return p;
    };
    indirectCall = function(p, tns, t, targetNode, argv, namespace, nodes){
      var ref$, ref1$, address, through, context, taskFunction;
      if (nodes == null) {
        return p.thenReject("Invalid nodes specified");
      }
      if ((targetNode != null ? (ref$ = targetNode.path) != null ? ref$.hostname : void 8 : void 8) == null || (targetNode != null ? (ref$ = targetNode.path) != null ? ref$.from : void 8 : void 8) == null || (targetNode != null ? (ref$ = targetNode.path) != null ? ref$.use : void 8 : void 8) == null) {
        return p.thenReject("Invalid node specified");
      }
      if ((namespace != null ? (ref$ = namespace[tns]) != null ? (ref1$ = ref$.tasks) != null ? (ref$ = ref1$[t]) != null ? ref$.fun : void 8 : void 8 : void 8 : void 8) == null) {
        return p.thenReject("Invalid task function.");
      }
      ref$ = tunnel.decomposeAddress(targetNode, nodes), address = ref$.address, through = ref$.through;
      disp("Launching `" + tns + ":" + t + "` on `" + address.hostname + ":" + address.port + "` through `" + through.hostname + "`");
      p = tunnel.mountTunnel(targetNode, p, argv.latency, nodes);
      context = {
        remote: {
          username: address.username,
          hostname: "localhost",
          port: address.use,
          credentials: address.credentials,
          access: address.access
        },
        tasks: namespace[tns].tasks,
        nodes: nodes,
        args: argv
      };
      taskFunction = namespace[tns].tasks[t].fun;
      if (taskFunction == null) {
        return p.thenReject("The function does not exist.");
      }
      p = p.then(function(){
        return taskFunction.apply(context);
      });
      return tunnel.unmountTunnel(targetNode, p);
    };
    invokeActions = function(p, tt, argv, nodes, namespace){
      var targetNode, i$, ref$, len$, tval, ref1$, tns, t;
      if ((nodes != null ? nodes[tt] : void 8) == null) {
        return p.thenReject("Skipping " + tt + ", invalid target-node ");
      }
      if (argv._.length === 0) {
        return p.thenReject("Pleas specify at least one task");
      }
      targetNode = nodes[tt];
      for (i$ = 0, len$ = (ref$ = argv._).length; i$ < len$; ++i$) {
        tval = ref$[i$];
        ref1$ = decomposeTask(tval), tns = ref1$[0], t = ref1$[1];
        if (namespace[tns] == null) {
          return p.thenReject("Please specify a valid namespace");
        }
        if (in$(t, _.pluck(namespace[tns].tasks, 'name'))) {
          if (targetNode.path.from == null) {
            p = directCall(p, tns, t, targetNode, argv, namespace, nodes);
          } else {
            p = indirectCall(p, tns, t, targetNode, argv, namespace, nodes);
          }
        } else {
          return p.thenReject("Sorry, no valid task named " + t);
        }
      }
      return p;
    };
    iface = {
      print: print,
      invokeActions: invokeActions,
      innerModule: innerModule,
      directCall: directCall,
      indirectCall: indirectCall
    };
    return iface;
  };
  module.exports = _module();
  function in$(x, arr){
    var i = -1, l = arr.length >>> 0;
    while (++i < l) if (x === arr[i] && i in arr) return true;
    return false;
  }
}).call(this);
