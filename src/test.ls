require! 'should'
require! 'sinon'
require! 'assert'

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

    it 'should instantiate connection module module', ->
        mod := require('./connect')
        should.exist(mod)

    it 'should create a connection `conn`', ->
        conn := mod.create-connection()
        should.exist(conn)

    it '`module.connect` should call `conn.connect`', ->
        expected = sinon.mock(conn).expects('connect').once()
        mod.connect(conn, { credentials: '/Users/zaccaria/.ssh/id_rsa'})
        expected.verify()

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
















