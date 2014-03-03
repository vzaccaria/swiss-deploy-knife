// Generated by LiveScript 1.2.0
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
  dispKo = winston.error;
  disp = winston.info;
  pdisp = console.log;
  pdeb = winston.warn;
  _.mixin(_.str.exports());
  _.str.include('Underscore.string', 'string');
  _module = function(){
    var scope, sendCommand, createConnection, connect, registerMsgHandlers, inject, innerModule, iface;
    this.otherGetCredentials = function(local){
      return require('fs').readFileSync(local.credentials);
    };
    sendCommand = function(conn, c, options){
      var d, output;
      d = __q.defer();
      disp("Executing command " + c);
      output = "";
      registerMsgHandlers(conn, d);
      conn.exec(c, function(err, stream){
        if (err) {
          d.reject(output);
          return;
        }
        stream.on('data', function(it){
          output = output + it;
          if ((options != null ? options.silent : void 8) == null) {
            return process.stdout.write(it);
          }
        });
        return stream.on('exit', function(code, signal){
          if (code !== 0) {
            return d.reject(output);
          } else {
            return d.resolve(output);
          }
        });
      });
      return d.promise;
    };
    createConnection = function(){
      var ssh2, conn;
      pdeb("Creating connection");
      ssh2 = require('ssh2');
      conn = new ssh2();
      return conn;
    };
    connect = function(conn, local){
      pdeb("Connecting to " + local.hostname);
      conn.connect({
        host: local.hostname,
        port: local.port,
        username: local.username,
        privateKey: otherGetCredentials(local)
      });
      return conn;
    };
    registerMsgHandlers = function(conn, defer){
      conn.on('connect', function(){
        return pdeb("Connected");
      });
      conn.on('error', function(){
        return defer.reject("Error on connection.");
      });
      return conn.on('close', function(){
        return pdeb("Closed");
      });
    };
    inject = function(o){
      return _.extend(this, o);
    };
    innerModule = function(){
      return root;
    };
    iface = {
      innerModule: innerModule,
      sendCommand: sendCommand,
      createConnection: createConnection,
      connect: connect,
      registerMsgHandlers: registerMsgHandlers,
      inject: inject
    };
    return iface;
  };
  module.exports = _module();
}).call(this);