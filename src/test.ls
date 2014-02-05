require! 'should'
require! 'sinon'
require! 'assert'

_ = require('underscore')

moment = require 'moment'
__q = require('q')

winston         = require('winston')

disp-ok = -> 
    winston.info "Ok"
disp-ko = -> 
    winston.error it?.toString()

disp    = winston.info
pdisp   = console.log
pdeb    = winston.warn

notifies-on-fail = (p, cb) ->
    p.then(disp-ko,(-> cb()))

notifies-on-success = (p, cb) ->
    p.then((-> cb()), disp-ko)

create-resolved-promise = ->
    d = __q.defer()
    p = d.promise   
    d.resolve()
    return p


create-rejected-promise = ->
    d = __q.defer()
    p = d.promise   
    d.reject()
    return p

psetup = (file) ->
    if file?
        winston.add(winston.transports.File, { filename: file });
        winston.remove(winston.transports.Console);
    else
        winston.remove(winston.transports.Console);
        winston.add(winston.transports.Console, { level: 'error', +colorize })
        # winston.add(winston.transports.Console, { +colorize })

patch-dependency = (module, depname, property, value) -->
    sinon.stub(module.inner-module()[depname], property, value)

unpatch-dependency = (module, depname, property) -->
    if not (_.is-array property)
        module.inner-module()[depname][property].restore()
    else 
        for e in property 
            module.inner-module()[depname][e].restore()

# dbg = false

# mdhead  = ->
#     if dbg
#         console.log ""
    
# mdprint = (msg, err, r, o) ->
#     if dbg
#         console.log "        ◦ #msg "
#         console.log "        ◦ [error #err, status #{r.statusCode}, #{o?} - #o]"

# mdp = (e) ->
#     if dbg
#         console.log "        ◦ #e"



psetup()

describe 'ssh command-on-wire connection', (empty)->

    var mod 
    var conn
    var mock-conn
    var target-module

    it 'should instantiate connection module module', ->
        mod := require('./connect')
        should.exist(mod)

    it 'should create a connection `conn`', ->
        conn := mod.create-connection()
        should.exist(conn)

    it '`module.connect` should call `conn.connect`', ->
        expected = sinon.mock(conn).expects('connect').once()
        s1 = sinon.stub mod.inner-module(), 'otherGetCredentials', ->
        mod.connect(conn, { credentials: '/Users/zaccaria/.ssh/id_sa'} )
        expected.verify()
        s1.called-once.should.be.equal(true)

    it '`module.send-command` should call `conn.exec` and get a succesful promise', (done) ->
        fake-stream = new (require('events').EventEmitter)()

        sinon.stub conn, 'exec', (c, cb) ->
                cb(null, fake-stream)

        p = mod.send-command(conn, "df")
        fake-stream.emit 'data', "fake output"
        fake-stream.emit 'exit', 0, 0
        p.then( -> done())
        conn.exec.restore() 

    it '`module.send-command` should call `conn.exec` and get a unsuccesful promise (command fails)', (done) ->
        fake-stream = new (require('events').EventEmitter)()

        sinon.stub conn, 'exec', (c, cb) ->
                cb(null, fake-stream)

        p = mod.send-command(conn, "df")
        fake-stream.emit 'data', "fake output"
        fake-stream.emit 'exit', 1, 0
        p.fail( -> done())
        conn.exec.restore() 

    it '`module.send-command` should call `conn.exec` and get a unsuccessful promise (command does not exist)', (done) ->
        sinon.stub conn, 'exec', (c, cb) ->
                cb(true, null)
        p = mod.send-command(conn, "df")
        p.fail( -> done())
        conn.exec.restore() 

    it '`module.send-command` should call `conn.exec` and get a unsuccesful promise (stream generates an error)', (done) ->
        fake-stream = new (require('events').EventEmitter)()

        sinon.stub conn, 'exec', (c, cb) ->
                cb(null, fake-stream)

        p = mod.send-command(conn, "df")
        conn.emit 'error'
        p.fail( -> done())
        conn.exec.restore() 

describe 'actions', (empty)->
    var act 
    act := require('./actions')
    var namespace 
    namespace :=
            test: 
                tasks: 
                        task1:
                             name: 'task1'   
                             fun: ->
                                d = __q.defer()
                                d.resolve('task finished')
                                return d.promise
                        taskfail:
                             name: 'taskfail'   
                             fun: ->
                                d = __q.defer()
                                d.reject('task finished with error')
                                return d.promise
            test2: 
                tasks:
                        task3:
                            name: 'task3'                     
                            fun: ->
                                d = __q.defer()
                                d.resolve('task finished')
                                return d.promise
                        taskfail:
                             name: 'taskfail'   
                             fun: ->
                                d = __q.defer()
                                d.reject('task finished with error')
                                return d.promise


            test3: 
                default-node: 's2'
                tasks:
                        task3:
                            name: 'task3'                     
                            fun: ->
                                d = __q.defer()
                                d.resolve('task finished')
                                return d.promise
                        taskfail:
                             name: 'taskfail'   
                             fun: ->
                                d = __q.defer()
                                d.reject('task finished with error')
                                return d.promise
    var nodes 
    nodes :=
        s1:
            description: "Hbomb"
            path: 
              username: "zaccaria" 
              hostname: "hbomb.elet.polimi.it" 
              port: "22" 
              credentials: '/Users/zaccaria/.ssh/id_rsa'
              hosttype: 'linux' 
              access: \ssh
        s2: 
            description: "Vagrant box"

            path: 
              from: \s1
              use: 4444
              username: "vagrant"
              hostname: "127.0.0.1"
              port: "2222"
              credentials: '/Users/zaccaria/.ssh/id_rsa'
              hosttype: 'linux' 
              access: \ssh

    var s1
    var s2
    var s3 
    var s4 

    describe 'actions.direct-call', (empty)->
        it '`module.direct-call` should invoke the correct task', (done) ->
            p = create-resolved-promise() 
            p = act.direct-call(p, 'test', 'task1', nodes['s1'], {}, namespace, nodes)
            p `notifies-on-success` done


        it '`module.direct-call` should throw with incorrect task', (done) ->
            p = create-resolved-promise() 
            p = act.direct-call(p, 'test', 'task2', nodes['s1'], {}, namespace, nodes)
            p `notifies-on-fail` done

        it '`module.direct-call` should throw with incorrect namespace', (done) ->
            p = create-resolved-promise() 
            p = act.direct-call(p, 'tes', 'task1', nodes['s1'], {}, namespace, nodes)
            p `notifies-on-fail` done

        it '`module.direct-call` should throw with incorrect namespace', (done) ->
            p = create-resolved-promise() 
            p = act.direct-call(p, 'test', 'task1', nodes['s1'], {}, null, nodes)
            p `notifies-on-fail` done

        it '`module.direct-call` should throw with incorrect node', (done) ->
            p = create-resolved-promise() 
            p = act.direct-call(p, 'test', 'task1', nodes, {}, namespace, nodes)
            p `notifies-on-fail` done

        it '`module.direct-call` should throw with incorrect nodes', (done) ->
            p = create-resolved-promise() 
            p = act.direct-call(p, 'test', 'task1', nodes['s1'], {}, namespace, null)
            p `notifies-on-fail` done

    describe 'actions.indirect-call', (empty)->
        it '`module.indirect-call` should invoke the correct task', (done) ->
            sinon.stub act.inner-module().tunnel, 'mountTunnel', create-resolved-promise
            sinon.stub act.inner-module().tunnel, 'unmountTunnel', create-resolved-promise
            p = create-resolved-promise() 
            p = act.indirect-call(p, 'test', 'task1', nodes['s2'], {}, namespace, nodes)
            p `notifies-on-success` done

        it '`module.indirect-call` should not invoke the correct task on a directly accessible node', (done) ->
            p = create-resolved-promise() 
            p = act.indirect-call(p, 'test', 'task1', nodes['s1'], {}, namespace, nodes)
            p `notifies-on-fail` done

        it '`module.indirect-call` should throw with incorrect task', (done) ->
            p = create-resolved-promise() 
            p = act.direct-call(p, 'test', 'task2', nodes['s2'], {}, namespace, nodes)
            p `notifies-on-fail` done

        it '`module.indirect-call` should throw with incorrect namespace', (done) ->
            p = create-resolved-promise() 
            p = act.direct-call(p, 'tes', 'task1', nodes['s2'], {}, namespace, nodes)
            p `notifies-on-fail` done

        it '`module.indirect-call` should throw with incorrect namespace', (done) ->
            p = create-resolved-promise() 
            p = act.direct-call(p, 'test', 'task1', nodes['s2'], {}, null, nodes)
            p `notifies-on-fail` done

        it '`module.indirect-call` should throw with incorrect node', (done) ->
            p = create-resolved-promise() 
            p = act.direct-call(p, 'test', 'task1', nodes, {}, namespace, nodes)
            p `notifies-on-fail` done

        it '`module.indirect-call` should throw with incorrect nodes', (done) ->
            p = create-resolved-promise() 
            p = act.direct-call(p, 'test', 'task1', nodes['s2'], {}, namespace, null)
            p `notifies-on-fail` done

        it '`module.indirect-call` should return a rejected promise on failed mount', (done) ->
            act.inner-module().tunnel.mount-tunnel.restore()
            act.inner-module().tunnel.unmount-tunnel.restore()
            sinon.stub act.inner-module().tunnel, 'mountTunnel', create-rejected-promise
            sinon.stub act.inner-module().tunnel, 'unmountTunnel', (t, p) -> return p
            p = create-resolved-promise() 
            p = act.indirect-call(p, 'test', 'task1', nodes['s2'], {}, namespace, nodes)
            p `notifies-on-fail` done
 
    describe 'actions.invoke-actions', (empty)->
        it 'should invoke the correct task', (done) ->
            act.inner-module().tunnel.mount-tunnel.restore()
            act.inner-module().tunnel.unmount-tunnel.restore()
            sinon.stub act.inner-module().tunnel, 'mountTunnel', create-resolved-promise
            sinon.stub act.inner-module().tunnel, 'unmountTunnel', create-resolved-promise
            p = create-resolved-promise() 
            p = act.invoke-actions(p, 's1', { _: [ 'test:task1'] }, nodes, namespace ) 
            p `notifies-on-success` done


        it 'should invoke the correct task', (done) ->
            act.inner-module().tunnel.mount-tunnel.restore()
            act.inner-module().tunnel.unmount-tunnel.restore()
            sinon.stub act.inner-module().tunnel, 'mountTunnel', create-resolved-promise
            sinon.stub act.inner-module().tunnel, 'unmountTunnel', create-resolved-promise
            p = create-resolved-promise() 
            p = act.invoke-actions(p, 's1', { namespace: 'test', _: [ 'task1'] }, nodes, namespace ) 
            p `notifies-on-success` done

        it 'should not invoke a non-existing task', (done) ->
            p = create-resolved-promise() 
            p = act.invoke-actions(p, 's1', { _: [ 'tes:task1'] }, nodes, namespace ) 
            p `notifies-on-fail` done

        it 'should fail on failing task', (done) ->
            p = create-resolved-promise() 
            p = act.invoke-actions(p, 's1', { _: [ 'test:task2'] }, nodes, namespace ) 
            p `notifies-on-fail` done

        it 'should fail on non-existing node', (done) ->
            p = create-resolved-promise() 
            p = act.invoke-actions(p, 's', { _: [ 'test:task1'] }, nodes, namespace ) 
            p `notifies-on-fail` done

        it 'should fail on incorrect params', (done) ->
            p = create-resolved-promise() 
            p = act.invoke-actions(p, 's', { _: [ 'test:task1'] }, null, namespace ) 
            p `notifies-on-fail` done

        it 'should fail on incorrect params', (done) ->
            p = create-resolved-promise() 
            p = act.invoke-actions(p, 's', { _: [ 'test:task1'] }, nodes, null) 
            p `notifies-on-fail` done

        it 'if first task fails, do not execute the second one', (done) ->
            s1 := sinon.spy(namespace['test'].tasks['task1'], 'fun')
            s2 := sinon.spy(namespace['test'].tasks['taskfail'], 'fun')
            p = create-resolved-promise() 
            p = act.invoke-actions(p, 's1', { _: [ 'test:taskfail', 'test:task1' ] }, nodes, namespace ) 

            p = p.fail ->
                    assert(s2.called-once)
                    assert(not s1.called-once)

            p `notifies-on-success` done

        it 'if first task does not exist, do not execute the second one', (done) ->
            namespace['test'].tasks['task1'].fun.restore()
            namespace['test'].tasks['taskfail'].fun.restore()
            s1 := sinon.spy(namespace['test'].tasks['task1'], 'fun')
            s2 := sinon.spy(namespace['test'].tasks['taskfail'], 'fun')
            p = create-resolved-promise() 
            p = act.invoke-actions(p, 's1', { _: [ 'test:taskfai', 'test:task1' ] }, nodes, namespace ) 

            p = p.fail ->
                    assert(not s2.called-once)
                    assert(not s1.called-once)

            p `notifies-on-success` done
        it 'if second task fails, execute the first one', (done) ->
            namespace['test'].tasks['task1'].fun.restore()
            namespace['test'].tasks['taskfail'].fun.restore()
            s1 := sinon.spy(namespace['test'].tasks['task1'], 'fun')
            s2 := sinon.spy(namespace['test'].tasks['taskfail'], 'fun')
            p = create-resolved-promise() 
            p = act.invoke-actions(p, 's1', { _: [ 'test:task1', 'test:taskfail' ] }, nodes, namespace ) 
            p = p.fail ->
                    assert(s1.called-once)
                    assert(s2.called-once)

            p `notifies-on-success` done

        it 'should invoke the correct task when a default node is not present', (done) ->
            act.inner-module().tunnel.mount-tunnel.restore()
            act.inner-module().tunnel.unmount-tunnel.restore()
            sinon.stub act.inner-module().tunnel, 'mountTunnel', create-resolved-promise
            sinon.stub act.inner-module().tunnel, 'unmountTunnel', create-resolved-promise
            s3 := sinon.spy(act.inner-module(), 'indirectCall')
            s4 := sinon.spy(act.inner-module(), 'directCall')
            s1 := sinon.spy(namespace['test2'].tasks['task3'], 'fun')
            p = create-resolved-promise() 
            p = act.invoke-actions(p, 's1', { _: [ 'test2:task3'] }, nodes, namespace ) 
            p = p.then ->
                    # console.log s4.get-call(0).args
                    assert(s4.get-call(0).args[3].description is 'Hbomb')
                    assert(s4.called-once)
                    assert(s1.called-once)
            p `notifies-on-success` done


        it 'should invoke the correct task when a default node is present', (done) ->

            act.inner-module().tunnel.mount-tunnel.restore()
            act.inner-module().tunnel.unmount-tunnel.restore()
            act.inner-module().direct-call.restore()
            act.inner-module().indirect-call.restore()

            sinon.stub act.inner-module().tunnel, 'mountTunnel', create-resolved-promise
            sinon.stub act.inner-module().tunnel, 'unmountTunnel', create-resolved-promise

            s3 := sinon.spy(act.inner-module(), 'indirectCall')
            s4 := sinon.spy(act.inner-module(), 'directCall')
            s1 := sinon.spy(namespace['test3'].tasks['task3'], 'fun')

            p = create-resolved-promise() 
            p = act.invoke-actions(p, 's1', { _: [ 'test3:task3'] }, nodes, namespace ) 
            p = p.then ->
                    assert(s3.get-call(0).args[3].description is 'Vagrant box')
                    assert(s3.called-once)
                    assert(s1.called-once)
            p `notifies-on-success` done

        it 'should invoke the correct task when a default node is present but forced from outside', (done) ->
            act.inner-module().tunnel.mount-tunnel.restore()
            act.inner-module().tunnel.unmount-tunnel.restore()
            act.inner-module().direct-call.restore()
            act.inner-module().indirect-call.restore()
            sinon.stub act.inner-module().tunnel, 'mountTunnel', create-resolved-promise
            sinon.stub act.inner-module().tunnel, 'unmountTunnel', create-resolved-promise
            s3 := sinon.spy(act.inner-module(), 'indirectCall')
            s4 := sinon.spy(act.inner-module(), 'directCall')
            p = create-resolved-promise() 
            p = act.invoke-actions(p, 's1', { _: [ 'test3:task3'], node: 's1' }, nodes, namespace ) 
            p = p.then ->
                    # console.log s4.get-call(0).args
                    assert(s4.get-call(0).args[3].description is 'Hbomb')
                    assert(s4.called-once)
            p `notifies-on-success` done

describe 'tasks and namespace', (empty)->
    var tsk
    var p
    tsk := require('./task')
    var ns 
    var spy

    ns = tsk.build-tasks [
        tsk.namespace 'general', 'general commands applicable to almost all access modes',
            # Use bound functions ~> inside tasks..
            tsk.task 'top', 'inspects processes', -> 
              tsk.run @remote, 'top -b -n 1 | head -n 12'
        tsk.namespace 'myns', 
            tsk.task 'xyz', ->
                console.log "no fun.."
        tsk.namespace 'myns2', { default-node: 's3'},
            tsk.task 'xyz', ->
                console.log "no fun.."
        ]

    describe 'tasks and namespaces', (empty)->

            it 'should create namespaces structure', ->
                should.exist(ns)
                should.exist(ns['general'])
                should.exist(ns['myns'])

            it 'should create tasks', ->
                should.exist(ns['general'].tasks['top'])
                should.exist(ns['myns'].tasks['xyz'])

            it 'should create metadata', ->
                ns['general'].tasks['top'].description.should.be.equal('inspects processes')
                ns['general'].tasks['top'].name.should.be.equal('top')
                should.exist(ns['myns'].tasks['xyz'].name)
                ns['myns'].tasks['xyz'].description.should.be.equal('')

            it 'should associate functions correctly', ->
                should.exist(ns['general'].tasks['top'].fun)
                _.is-function(ns['general'].tasks['top'].fun).should.be.equal(true)
                should.exist(ns['myns'].tasks['xyz'].fun)
                _.is-function(ns['myns'].tasks['xyz'].fun).should.be.equal(true)

            it 'should recognize a default node', ->
                should.exist(ns['myns2'].tasks['xyz'].fun)
                _.is-function(ns['myns2'].tasks['xyz'].fun).should.be.equal(true)
                ns['myns2'].default-node.should.be.equal('s3')

    describe 'run', (empty)->
        var fake-conn
        var patch-connect 

        patch-connect = patch-dependency(tsk, 'connect')
        unpatch-connect = unpatch-dependency(tsk, 'connect')

        new-connection = ->
            fc = new (require('events').EventEmitter)()
            fc.end = sinon.stub().returns(true)
            fc.ok  = -> fc.emit 'ready'
            return fc

        it 'should return a rejected promise if command fails', (done) ->

            fake-conn := new-connection()
            patch-connect 'createConnection',   -> {}
            patch-connect 'connect',            -> fake-conn
            spy := patch-connect 'sendCommand', -> create-rejected-promise()

            p := tsk.run({}, 'a', {})
            fake-conn.ok() 
            p `notifies-on-fail` done

        it 'should return a resolved promise', (done) ->
            unpatch-connect ['createConnection', 'connect', 'sendCommand']

            fake-conn := new-connection()
            patch-connect 'createConnection',   -> {}
            patch-connect 'connect',            -> fake-conn
            spy := patch-connect 'sendCommand', -> create-resolved-promise()

            p := tsk.run({}, 'a', {})
            fake-conn.ok() 
            p `notifies-on-success` done



        it 'should send the correct command', ->
            spy.calledOnce.should.be.equal(true)
            spy.firstCall.args[1].should.be.equal('a')

        it 'should be called twice', (done) ->
            fake-conn := new (require('events').EventEmitter)()
            fake-conn.end = sinon.stub().returns(true)
            p := tsk.run({}, [ 'b', 'c' ], {})
            fake-conn.emit 'ready'
            p `notifies-on-success` done

        it 'should send two commands', ->
            spy.calledThrice.should.be.equal(true)
            spy.secondCall.args[1].should.be.equal('b')
            spy.thirdCall.args[1].should.be.equal('c')

        it 'run-local should interpret options', (done) ->
            fake-conn := new (require('events').EventEmitter)()
            fake-conn.end = sinon.stub().returns(true)
            p := tsk.run-local({}, ['d'], {})
            fake-conn.emit 'ready'
            p `notifies-on-success` (done)

        it 'run-local should have invoked run underneath', ->
            spy.lastCall.args[1].should.be.equal('d')

        it 'run-local should interpret options', (done) ->
            fake-conn := new (require('events').EventEmitter)()
            fake-conn.end = sinon.stub().returns(true)
            da-node = 
                login:
                    run-as-sudo : true
                    directory   : '~/test/infoweb'

            p := tsk.run-local(da-node, ['a'], {})
            fake-conn.emit 'ready'
            p `notifies-on-success` (done)

        it 'run-local should have invoked run underneath', ->
            spy.lastCall.args[1].should.be.equal('cd ~/test/infoweb && sudo a')

        it 'run-local should interpret options', (done) ->
            fake-conn := new (require('events').EventEmitter)()
            fake-conn.end = sinon.stub().returns(true)
            da-node = 
                login:
                    shell       : tsk.bsh
                    run-as-sudo : false
                    directory   : '~/test/infoweb'

            p := tsk.run-local(da-node, ['a'], {})
            fake-conn.emit 'ready'
            p `notifies-on-success` (done)

        it 'run-local should have invoked run underneath', ->
            spy.lastCall.args[1].should.be.equal('bash -l -c \'cd ~/test/infoweb && a\'')


        it 'run-local should interpret options', (done) ->
            fake-conn := new (require('events').EventEmitter)()
            fake-conn.end = sinon.stub().returns(true)
            da-node = 
                login:
                    run-as-sudo : true
                    directory   : '~/test/infoweb'

            p := tsk.run-local(da-node, 'abc', {})
            fake-conn.emit 'ready'
            p `notifies-on-success` (done)

        it 'run-local should have invoked run underneath', ->
            spy.lastCall.args[1].should.be.equal('cd ~/test/infoweb && sudo abc')

        it 'run-local safe should return a successful promise if command fails', (done) ->
            unpatch-connect ['createConnection', 'connect', 'sendCommand']

            fake-conn := new-connection()
            patch-connect 'createConnection',   -> {}
            patch-connect 'connect',            -> fake-conn
            spy := patch-connect 'sendCommand', -> create-rejected-promise()

            p := tsk.run-local-safe({}, 'a', {})
            fake-conn.ok() 
            p `notifies-on-success` done

    describe 'sequence', (empty)->       
        var namespace 
        namespace :=
                  test: 
                        tasks: 
                                task1:
                                     name: 'task1'   
                                     fun: ->
                                        d = __q.defer()
                                        d.resolve('task finished')
                                        return d.promise

                                taskfail:
                                     name: 'taskfail'   
                                     fun: ->
                                        d = __q.defer()
                                        d.reject('task finished with error')
                                        return d.promise
        var s1                                
        it 'should execute a single task', (done) ->
            s1 := sinon.spy(namespace['test'].tasks['task1'], 'fun')
            promise = tsk.sequence(namespace.test, 'task1')
            promise `notifies-on-success` done

        it 'should execute only once the task', ->
            s1.called-once.should.be.equal(true)

        it 'should execute an array sequence', (done) ->
            promise = tsk.sequence(namespace.test, [ 'task1', 'task1'])
            promise `notifies-on-success` done 
            
        it 'should execute an array sequence', ->
            s1.calledThrice.should.be.equal(true)

        it 'should not complete a sequence if a task fails', (done) ->
            promise = tsk.sequence(namespace.test, [ 'taskfail', 'task1'])
            promise `notifies-on-fail` done

        it 'should not execute a task after a failed one', ->
            s1.calledThrice.should.be.equal(true)


describe 'ssh commands', (empty)->

    var s1, s2, s3, fake-proc, target-module, nodes, result, command

    target-module := require('./ssh')

    nodes :=
        s1:
            description: "Hbomb"
            path: 
              username: "zaccaria" 
              hostname: "hbomb.elet.polimi.it" 
              port: "22" 
              credentials: '/Users/zaccaria/.ssh/id_rsa'
              hosttype: 'linux' 
              access: \ssh
        s2: 
            description: "Vagrant box"

            path: 
              from: \s1
              use: 4444
              username: "vagrant"
              hostname: "127.0.0.1"
              port: "2222"
              credentials: '/Users/zaccaria/.ssh/id_rsa'
              hosttype: 'linux' 
              access: \ssh


    it '`module` should contain injectable methods', ->
        should.exist(target-module.inner-module().child_process.spawn)
        should.exist(target-module.inner-module().shelljs)
        should.exist(target-module.inner-module().setup-temporary-directory)

    it '`module` should invoke load correctly..', (done) ->
        fake-proc:= new (require('events').EventEmitter)()
        sinon.stub target-module.inner-module(), 'getCredentials', -> 
            return \xyz
        s1 := sinon.stub target-module.inner-module(), 'setupTemporaryDirectory', ->
            return 'pippo'

        s2 := sinon.stub target-module.inner-module(), 'removeTemporaryDirectory', ->

        s3 := sinon.stub target-module.inner-module().shelljs, 'cat', ->
                " [ { \"data\"   :      1 } ] "

        sinon.stub target-module.inner-module().child_process, 'spawn', -> 
            command := arguments
            fake-proc 

        promise = target-module.load { from: 's1:abc', in: nodes }

        result := {}

        promise = promise.then -> 
            result := it

        fake-proc.emit 'close'

        promise `notifies-on-success` done

    it '`module` should invoke tmp dir functions', ->
        s1.calledOnce.should.be.equal(true)
        s2.calledOnce.should.be.equal(true)
        s3.calledOnce.should.be.equal(true)
        command[1][1].should.be.equal('set ftp:ssl-allow false; open ftp://zaccaria:xyz@hbomb.elet.polimi.it; get abc -o pippo/temp.json; bye;')
        should.exist(result)
        should.exist(result[0])
        should.exist(result[0].data)
        result[0].data.should.be.equal(1)
 
    it '`module` should invoke read correctly and recognize errors..', (done) ->
        fake-proc := new (require('events').EventEmitter)()
        promise = target-module.load { from: 's1:abc', in: nodes }
        result := {}
        promise = promise.then -> 
            result := it
        fake-proc.emit 'error'
        promise `notifies-on-fail` done

    it '`module` should invoke save correctly..', (done) ->
        fake-proc:= new (require('events').EventEmitter)()
        sinon.stub target-module.inner-module().fs, 'writeFile', (what, how, after) ->
            after()
        promise = target-module.save { d: 1}, { to: 's2:abc', in: nodes }
        fake-proc.emit 'close'
        promise `notifies-on-success` done

    it 'should invoke tmp dir functions', ->
        s1.calledThrice.should.be.equal(true)
        s2.calledThrice.should.be.equal(true)
        command[1][1].should.be.equal('set ftp:ssl-allow false; open ftp://vagrant:xyz@127.0.0.1; put pippo/temp.json -o abc; bye;')






