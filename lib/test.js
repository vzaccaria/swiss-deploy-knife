(function(){
  var should, sinon, assert, _, moment, __q, winston, dispOk, dispKo, disp, pdisp, pdeb, notifiesOnFail, notifiesOnSuccess, createResolvedPromise, createRejectedPromise, psetup;
  should = require('should');
  sinon = require('sinon');
  assert = require('assert');
  _ = require('underscore');
  moment = require('moment');
  __q = require('q');
  winston = require('winston');
  dispOk = function(){
    return winston.info("Ok");
  };
  dispKo = function(it){
    return winston.error(it != null ? it.toString() : void 8);
  };
  disp = winston.info;
  pdisp = console.log;
  pdeb = winston.warn;
  notifiesOnFail = function(p, cb){
    return p.then(dispKo, function(){
      return cb();
    });
  };
  notifiesOnSuccess = function(p, cb){
    return p.then(function(){
      return cb();
    }, dispKo);
  };
  createResolvedPromise = function(){
    var d, p;
    d = __q.defer();
    p = d.promise;
    d.resolve();
    return p;
  };
  createRejectedPromise = function(){
    var d, p;
    d = __q.defer();
    p = d.promise;
    d.reject();
    return p;
  };
  psetup = function(file){
    if (file != null) {
      winston.add(winston.transports.File, {
        filename: file
      });
      return winston.remove(winston.transports.Console);
    } else {
      winston.remove(winston.transports.Console);
      return winston.add(winston.transports.Console, {
        level: 'error',
        colorize: true
      });
    }
  };
  psetup();
  describe('ssh command-on-wire connection', function(empty){
    var mod, conn, mockConn;
    it('should instantiate connection module module', function(){
      mod = require('./connect');
      return should.exist(mod);
    });
    it('should create a connection `conn`', function(){
      conn = mod.createConnection();
      return should.exist(conn);
    });
    it('`module.connect` should call `conn.connect`', function(){
      var expected;
      expected = sinon.mock(conn).expects('connect').once();
      mod.connect(conn, {
        credentials: '/Users/zaccaria/.ssh/id_rsa'
      });
      return expected.verify();
    });
    it('`module.send-command` should call `conn.exec` and get a succesful promise', function(done){
      var fakeStream, p;
      fakeStream = new (require('events').EventEmitter)();
      sinon.stub(conn, 'exec', function(c, cb){
        return cb(null, fakeStream);
      });
      p = mod.sendCommand(conn, "df");
      fakeStream.emit('data', "fake output");
      fakeStream.emit('exit', 0, 0);
      p.then(function(){
        return done();
      });
      return conn.exec.restore();
    });
    it('`module.send-command` should call `conn.exec` and get a unsuccesful promise (command fails)', function(done){
      var fakeStream, p;
      fakeStream = new (require('events').EventEmitter)();
      sinon.stub(conn, 'exec', function(c, cb){
        return cb(null, fakeStream);
      });
      p = mod.sendCommand(conn, "df");
      fakeStream.emit('data', "fake output");
      fakeStream.emit('exit', 1, 0);
      p.fail(function(){
        return done();
      });
      return conn.exec.restore();
    });
    it('`module.send-command` should call `conn.exec` and get a unsuccessful promise (command does not exist)', function(done){
      var p;
      sinon.stub(conn, 'exec', function(c, cb){
        return cb(true, null);
      });
      p = mod.sendCommand(conn, "df");
      p.fail(function(){
        return done();
      });
      return conn.exec.restore();
    });
    return it('`module.send-command` should call `conn.exec` and get a unsuccesful promise (stream generates an error)', function(done){
      var fakeStream, p;
      fakeStream = new (require('events').EventEmitter)();
      sinon.stub(conn, 'exec', function(c, cb){
        return cb(null, fakeStream);
      });
      p = mod.sendCommand(conn, "df");
      conn.emit('error');
      p.fail(function(){
        return done();
      });
      return conn.exec.restore();
    });
  });
  describe('actions', function(empty){
    var act, namespace, nodes, s1, s2;
    act = require('./actions');
    namespace = {
      test: {
        tasks: {
          task1: {
            name: 'task1',
            fun: function(){
              var d;
              d = __q.defer();
              d.resolve('task finished');
              return d.promise;
            }
          },
          taskfail: {
            name: 'taskfail',
            fun: function(){
              var d;
              d = __q.defer();
              d.reject('task finished with error');
              return d.promise;
            }
          }
        }
      }
    };
    nodes = {
      s1: {
        description: "Hbomb",
        path: {
          username: "zaccaria",
          hostname: "hbomb.elet.polimi.it",
          port: "22",
          credentials: '/Users/zaccaria/.ssh/id_rsa',
          hosttype: 'linux',
          access: 'ssh'
        }
      },
      s2: {
        description: "Vagrant box",
        path: {
          from: 's1',
          use: 4444,
          username: "vagrant",
          hostname: "127.0.0.1",
          port: "2222",
          credentials: '/Users/zaccaria/.ssh/id_rsa',
          hosttype: 'linux',
          access: 'ssh'
        }
      }
    };
    describe('actions.direct-call', function(empty){
      it('`module.direct-call` should invoke the correct task', function(done){
        var p;
        p = createResolvedPromise();
        p = act.directCall(p, 'test', 'task1', nodes['s1'], {}, namespace, nodes);
        return notifiesOnSuccess(p, done);
      });
      it('`module.direct-call` should throw with incorrect task', function(done){
        var p;
        p = createResolvedPromise();
        p = act.directCall(p, 'test', 'task2', nodes['s1'], {}, namespace, nodes);
        return notifiesOnFail(p, done);
      });
      it('`module.direct-call` should throw with incorrect namespace', function(done){
        var p;
        p = createResolvedPromise();
        p = act.directCall(p, 'tes', 'task1', nodes['s1'], {}, namespace, nodes);
        return notifiesOnFail(p, done);
      });
      it('`module.direct-call` should throw with incorrect namespace', function(done){
        var p;
        p = createResolvedPromise();
        p = act.directCall(p, 'test', 'task1', nodes['s1'], {}, null, nodes);
        return notifiesOnFail(p, done);
      });
      it('`module.direct-call` should throw with incorrect node', function(done){
        var p;
        p = createResolvedPromise();
        p = act.directCall(p, 'test', 'task1', nodes, {}, namespace, nodes);
        return notifiesOnFail(p, done);
      });
      return it('`module.direct-call` should throw with incorrect nodes', function(done){
        var p;
        p = createResolvedPromise();
        p = act.directCall(p, 'test', 'task1', nodes['s1'], {}, namespace, null);
        return notifiesOnFail(p, done);
      });
    });
    describe('actions.indirect-call', function(empty){
      it('`module.indirect-call` should invoke the correct task', function(done){
        var p;
        sinon.stub(act.innerModule().tunnel, 'mountTunnel', createResolvedPromise);
        sinon.stub(act.innerModule().tunnel, 'unmountTunnel', createResolvedPromise);
        p = createResolvedPromise();
        p = act.indirectCall(p, 'test', 'task1', nodes['s2'], {}, namespace, nodes);
        return notifiesOnSuccess(p, done);
      });
      it('`module.indirect-call` should not invoke the correct task on a directly accessible node', function(done){
        var p;
        p = createResolvedPromise();
        p = act.indirectCall(p, 'test', 'task1', nodes['s1'], {}, namespace, nodes);
        return notifiesOnFail(p, done);
      });
      it('`module.indirect-call` should throw with incorrect task', function(done){
        var p;
        p = createResolvedPromise();
        p = act.directCall(p, 'test', 'task2', nodes['s2'], {}, namespace, nodes);
        return notifiesOnFail(p, done);
      });
      it('`module.indirect-call` should throw with incorrect namespace', function(done){
        var p;
        p = createResolvedPromise();
        p = act.directCall(p, 'tes', 'task1', nodes['s2'], {}, namespace, nodes);
        return notifiesOnFail(p, done);
      });
      it('`module.indirect-call` should throw with incorrect namespace', function(done){
        var p;
        p = createResolvedPromise();
        p = act.directCall(p, 'test', 'task1', nodes['s2'], {}, null, nodes);
        return notifiesOnFail(p, done);
      });
      it('`module.indirect-call` should throw with incorrect node', function(done){
        var p;
        p = createResolvedPromise();
        p = act.directCall(p, 'test', 'task1', nodes, {}, namespace, nodes);
        return notifiesOnFail(p, done);
      });
      it('`module.indirect-call` should throw with incorrect nodes', function(done){
        var p;
        p = createResolvedPromise();
        p = act.directCall(p, 'test', 'task1', nodes['s2'], {}, namespace, null);
        return notifiesOnFail(p, done);
      });
      return it('`module.indirect-call` should return a rejected promise on failed mount', function(done){
        var p;
        act.innerModule().tunnel.mountTunnel.restore();
        act.innerModule().tunnel.unmountTunnel.restore();
        sinon.stub(act.innerModule().tunnel, 'mountTunnel', createRejectedPromise);
        sinon.stub(act.innerModule().tunnel, 'unmountTunnel', function(t, p){
          return p;
        });
        p = createResolvedPromise();
        p = act.indirectCall(p, 'test', 'task1', nodes['s2'], {}, namespace, nodes);
        return notifiesOnFail(p, done);
      });
    });
    return describe('actions.invoke-actions', function(empty){
      it('should invoke the correct task', function(done){
        var p;
        act.innerModule().tunnel.mountTunnel.restore();
        act.innerModule().tunnel.unmountTunnel.restore();
        sinon.stub(act.innerModule().tunnel, 'mountTunnel', createResolvedPromise);
        sinon.stub(act.innerModule().tunnel, 'unmountTunnel', createResolvedPromise);
        p = createResolvedPromise();
        p = act.invokeActions(p, 's1', {
          _: ['test:task1']
        }, nodes, namespace);
        return notifiesOnSuccess(p, done);
      });
      it('should not invoke a non-existing task', function(done){
        var p;
        p = createResolvedPromise();
        p = act.invokeActions(p, 's1', {
          _: ['tes:task1']
        }, nodes, namespace);
        return notifiesOnFail(p, done);
      });
      it('should fail on failing task', function(done){
        var p;
        p = createResolvedPromise();
        p = act.invokeActions(p, 's1', {
          _: ['test:task2']
        }, nodes, namespace);
        return notifiesOnFail(p, done);
      });
      it('should fail on non-existing node', function(done){
        var p;
        p = createResolvedPromise();
        p = act.invokeActions(p, 's', {
          _: ['test:task1']
        }, nodes, namespace);
        return notifiesOnFail(p, done);
      });
      it('should fail on incorrect params', function(done){
        var p;
        p = createResolvedPromise();
        p = act.invokeActions(p, 's', {
          _: ['test:task1']
        }, null, namespace);
        return notifiesOnFail(p, done);
      });
      it('should fail on incorrect params', function(done){
        var p;
        p = createResolvedPromise();
        p = act.invokeActions(p, 's', {
          _: ['test:task1']
        }, nodes, null);
        return notifiesOnFail(p, done);
      });
      it('if first task fails, do not execute the second one', function(done){
        var p;
        s1 = sinon.spy(namespace['test'].tasks['task1'], 'fun');
        s2 = sinon.spy(namespace['test'].tasks['taskfail'], 'fun');
        p = createResolvedPromise();
        p = act.invokeActions(p, 's1', {
          _: ['test:taskfail', 'test:task1']
        }, nodes, namespace);
        p = p.fail(function(){
          assert(s2.calledOnce);
          return assert(!s1.calledOnce);
        });
        return notifiesOnSuccess(p, done);
      });
      it('if first task does not exist, do not execute the second one', function(done){
        var p;
        namespace['test'].tasks['task1'].fun.restore();
        namespace['test'].tasks['taskfail'].fun.restore();
        s1 = sinon.spy(namespace['test'].tasks['task1'], 'fun');
        s2 = sinon.spy(namespace['test'].tasks['taskfail'], 'fun');
        p = createResolvedPromise();
        p = act.invokeActions(p, 's1', {
          _: ['test:taskfai', 'test:task1']
        }, nodes, namespace);
        p = p.fail(function(){
          assert(!s2.calledOnce);
          return assert(!s1.calledOnce);
        });
        return notifiesOnSuccess(p, done);
      });
      return it('if second task fails, execute the first one', function(done){
        var p;
        namespace['test'].tasks['task1'].fun.restore();
        namespace['test'].tasks['taskfail'].fun.restore();
        s1 = sinon.spy(namespace['test'].tasks['task1'], 'fun');
        s2 = sinon.spy(namespace['test'].tasks['taskfail'], 'fun');
        p = createResolvedPromise();
        p = act.invokeActions(p, 's1', {
          _: ['test:task1', 'test:taskfail']
        }, nodes, namespace);
        p = p.fail(function(){
          assert(s1.calledOnce);
          return assert(s2.calledOnce);
        });
        return notifiesOnSuccess(p, done);
      });
    });
  });
  describe('tasks and namespace', function(empty){
    var tsk, p, ns, spy;
    tsk = require('./task');
    ns = tsk.buildTasks([
      tsk.namespace('general', 'general commands applicable to almost all access modes', tsk.task('top', 'inspects processes', function(){
        return tsk.run(this.remote, 'top -b -n 1 | head -n 12');
      })), tsk.namespace('myns', tsk.task('xyz', function(){
        return console.log("no fun..");
      }))
    ]);
    describe('tasks and namespaces', function(empty){
      it('should create namespaces structure', function(){
        should.exist(ns);
        should.exist(ns['general']);
        return should.exist(ns['myns']);
      });
      it('should create tasks', function(){
        should.exist(ns['general'].tasks['top']);
        return should.exist(ns['myns'].tasks['xyz']);
      });
      it('should create metadata', function(){
        ns['general'].tasks['top'].description.should.be.equal('inspects processes');
        ns['general'].tasks['top'].name.should.be.equal('top');
        should.exist(ns['myns'].tasks['xyz'].name);
        return ns['myns'].tasks['xyz'].description.should.be.equal('');
      });
      return it('should associate functions correctly', function(){
        should.exist(ns['general'].tasks['top'].fun);
        _.isFunction(ns['general'].tasks['top'].fun).should.be.equal(true);
        should.exist(ns['myns'].tasks['xyz'].fun);
        return _.isFunction(ns['myns'].tasks['xyz'].fun).should.be.equal(true);
      });
    });
    describe('run', function(empty){
      var fakeConn;
      it('should return a resolved promise', function(done){
        fakeConn = new (require('events').EventEmitter)();
        sinon.stub(tsk.innerModule().connect, 'createConnection', function(){
          return {};
        });
        sinon.stub(tsk.innerModule().connect, 'connect', function(){
          return fakeConn;
        });
        spy = sinon.stub(tsk.innerModule().connect, 'sendCommand', function(){
          return createResolvedPromise();
        });
        fakeConn.end = sinon.stub().returns(true);
        p = tsk.run({}, 'hey', {});
        fakeConn.emit('ready');
        return notifiesOnSuccess(p, done);
      });
      it('should send the correct command', function(){
        spy.calledOnce.should.be.equal(true);
        return spy.firstCall.args[1].should.be.equal('hey');
      });
      it('should be called twice', function(done){
        fakeConn = new (require('events').EventEmitter)();
        fakeConn.end = sinon.stub().returns(true);
        p = tsk.run({}, ['a', 'b'], {});
        fakeConn.emit('ready');
        return notifiesOnSuccess(p, done);
      });
      return it('should send two commands', function(){
        spy.calledThrice.should.be.equal(true);
        spy.secondCall.args[1].should.be.equal('a');
        return spy.thirdCall.args[1].should.be.equal('b');
      });
    });
    return describe('sequence', function(empty){
      var namespace, s1;
      namespace = {
        test: {
          tasks: {
            task1: {
              name: 'task1',
              fun: function(){
                var d;
                d = __q.defer();
                d.resolve('task finished');
                return d.promise;
              }
            },
            taskfail: {
              name: 'taskfail',
              fun: function(){
                var d;
                d = __q.defer();
                d.reject('task finished with error');
                return d.promise;
              }
            }
          }
        }
      };
      it('should execute a single task', function(done){
        var promise;
        s1 = sinon.spy(namespace['test'].tasks['task1'], 'fun');
        promise = tsk.sequence(namespace.test, 'task1');
        return notifiesOnSuccess(promise, done);
      });
      it('should execute only once the task', function(){
        return s1.calledOnce.should.be.equal(true);
      });
      it('should execute an array sequence', function(done){
        var promise;
        promise = tsk.sequence(namespace.test, ['task1', 'task1']);
        return notifiesOnSuccess(promise, done);
      });
      it('should execute an array sequence', function(){
        return s1.calledThrice.should.be.equal(true);
      });
      it('should not complete a sequence if a task fails', function(done){
        var promise;
        promise = tsk.sequence(namespace.test, ['taskfail', 'task1']);
        return notifiesOnFail(promise, done);
      });
      return it('should not execute a task after a failed one', function(){
        return s1.calledThrice.should.be.equal(true);
      });
    });
  });
}).call(this);
