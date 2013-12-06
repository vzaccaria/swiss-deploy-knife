(function(){
  var _, moment, fs, color, ref$, spawn, kill, __q, sh, os, shelljs, cl, ut, winston, dispOk, dispKo, disp, pdisp, pdeb, _module;
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
    var scope, init, ch, createTunnel, closeTunnel, decomposeAddress, mountTunnel, unmountTunnel, iface;
    init = function(data){
      return scope = data;
    };
    ch = void 8;
    createTunnel = function(address, through){
      var d, args;
      d = __q.defer();
      if (through == null) {
        dispKo("Cannot create tunnel");
        d.reject("Cannot create tunnel");
      } else {
        args = ['-NL', address.use + ":" + address.hostname + ":" + address.port, through.username + "@" + through.hostname];
        pdeb("Executing command `ssh` " + args[0] + ", " + args[1] + ", " + args[2]);
        ch = spawn('ssh', args);
        pdeb("Command has pid: " + ch.pid);
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
    closeTunnel = function(){
      sh.exec("kill -9 " + ch.pid);
      ch = void 8;
      return true;
    };
    decomposeAddress = function(target, nodes){
      return {
        address: target.path,
        through: nodes[target.path.from].path
      };
    };
    mountTunnel = function(target, p, latency, nodes){
      var ref$, address, through;
      ref$ = decomposeAddress(target, nodes), address = ref$.address, through = ref$.through;
      p = p.then(function(){
        return createTunnel(address, through);
      });
      if (latency != null) {
        disp("Using latency " + latency);
        p = p.then(function(){
          return __q.delay(latency);
        });
      }
      return p;
    };
    unmountTunnel = function(target, p){
      p = p.then(function(){
        return closeTunnel();
      }, function(it){
        closeTunnel();
        throw it;
      });
      return p;
    };
    iface = {
      mountTunnel: mountTunnel,
      unmountTunnel: unmountTunnel,
      decomposeAddress: decomposeAddress
    };
    return iface;
  };
  module.exports = _module();
}).call(this);
