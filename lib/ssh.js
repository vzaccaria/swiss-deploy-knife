(function(){
  var _, moment, fs, color, ref$, spawn, kill, __q, sh, os, shelljs, cl, ut, winston, cnn, dispOk, dispKo, disp, pdisp, pdeb, lftpScript, src, otm, cwd, setupTemporaryDirectory, removeTemporaryDirectory, lftpScriptPut, _module, split$ = ''.split;
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
  cnn = require('./connect');
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
  lftpScript = function(us, pw, url){
    return "set ftp:ssl-allow false; open ftp://" + us + ":" + pw + "@" + url + ";";
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
  lftpScriptPut = function(us, pw, url, f, r){
    return "set ftp:ssl-allow false; open ftp://" + us + ":" + pw + "@" + url + "; put " + f + " -o " + r + "; bye;";
  };
  _module = function(){
    var scope, get, put, openTerminal, save, init, iface;
    get = function(local, remotePath, localPath){
      var e, conn, shutdownOk, shutdownFail;
      e = __q.defer();
      conn = cnn.createConnection();
      conn = cnn.connect(conn, local);
      cnn.registerMsgHandlers(conn);
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
    put = function(local, localPath, remotePath){
      var e, conn, shutdownOk, shutdownFail;
      e = __q.defer();
      conn = cnn.createConnection();
      conn = cnn.connect(conn, local);
      cnn.registerMsgHandlers(conn);
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
    openTerminal = function(address){
      var d, args, ch2, us, url, pw, cc;
      d = __q.defer();
      if (address.access === 'ssh') {
        args = [address.username + "@" + address.hostname, "-p", address.port + ""];
        pdeb("Executing command `ssh` " + args[0] + ", " + args[1] + ", " + args[2]);
        ch2 = spawn('ssh', args, {
          stdio: 'inherit'
        });
        ch2.on('error', function(){
          return d.reject("Failed connection");
        });
        ch2.on('close', function(){
          return d.resolve("Exited from command line.");
        });
        return d.promise;
      }
      if (address.access === 'ftp') {
        us = address.username;
        url = address.hostname;
        pw = require(address.credentials)[url][us];
        args = ["-e", lftpScript(us, pw, url)];
        pdeb("Executing command `lftp` " + args[0] + ", " + args[1]);
        cc = spawn('lftp', args, {
          stdio: 'inherit'
        });
        cc.on('error', function(){
          return d.reject("Failed connection");
        });
        cc.on('close', function(){
          return d.resolve('Exited from ftp');
        });
        return d.promise;
      }
      d.reject("Invalid " + address.access + " specified as access mode.");
      return d.promise;
    };
    save = function(what, options){
      var d, ref$, node, filename, nn, dd;
      d = __q.defer();
      if (options['in'] == null && options.to == null) {
        d.reject("Sorry, invalid options for save");
      }
      ref$ = split$.call(options.to, ':'), node = ref$[0], filename = ref$[1];
      if (options['in'][node] == null) {
        d.reject("Sorry, " + node + " does not exist");
      }
      nn = options['in'][node].path;
      disp("Saving output to ftp://" + nn.hostname + ":" + filename);
      dd = setupTemporaryDirectory();
      fs.writeFile(dd + "/temp.json", what, function(err){
        var us, url, pw, args, cc;
        if (err) {
          d.reject("Problems writing " + dd + "/temp.json");
          return;
        }
        us = nn.username;
        url = nn.hostname;
        pw = require(nn.credentials)[url][us];
        args = ["-e", lftpScriptPut(us, pw, url, dd + "/temp.json", filename)];
        cc = spawn('lftp', args);
        cc.on('error', function(){
          return d.reject("Failed connection");
        });
        return cc.on('close', function(){
          return d.resolve('Exited from ftp');
        });
      });
      return d.promise;
    };
    init = function(data){
      return scope = data;
    };
    iface = {
      get: get,
      put: put,
      openTerminal: openTerminal
    };
    return iface;
  };
  module.exports = _module();
}).call(this);
