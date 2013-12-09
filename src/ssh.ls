_               = require('underscore')
_.str           = require('underscore.string');
moment          = require 'moment'
fs              = require 'fs'
color           = require('ansi-color').set
{ spawn, kill } = require('child_process')
__q             = require('q')
sh              = require('shelljs')
os              = require('os')
shelljs         = sh
cl              = require('clark')
ut              = require('utf-8')
winston         = require('winston')
cnn             = require('./connect')

disp-ok = -> winston.info "Ok"
disp-ko = -> 
  winston.error it.toString()
disp    = winston.info
pdisp   = console.log
pdeb    = winston.warn

_.mixin(_.str.exports());
_.str.include('Underscore.string', 'string');


lftp-script = (us, pw, url) -> 
    """set ftp:ssl-allow false; open ftp://#us:#pw@#url;"""

src = __dirname
otm = if (os.tmpdir?) then os.tmpdir() else "/var/tmp"
cwd = process.cwd()

setup-temporary-directory = ->
    name = "tmp_#{moment().format('HHmmss')}_tmp"
    dire = "#{otm}/#{name}" 
    shelljs.mkdir '-p', dire
    return dire


remove-temporary-directory = (dir) ->
    shelljs.rm '-rf', dir 

lftp-script-put = (us, pw, url, f, r) -> 
    """set ftp:ssl-allow false; open ftp://#us:#pw@#url; put #f -o #r; bye;"""

_module = ->

    var scope 

    get = (local, remote-path, local-path) ->

        e = __q.defer()
        conn = cnn.create-connection()
        conn = cnn.connect(conn, local)
        cnn.register-msg-handlers(conn)

        shutdown-ok = -> 
                conn.end()
                e.resolve()

        shutdown-fail = ->
                conn.end()
                e.reject(it)      


        conn.on 'ready', -> 
            conn.sftp (err, sftp) ->
                if err 
                    shutdown-fail()
                else 
                    sftp.fast-get remote-path, local-path, (err) ->
                        if err 
                            shutdown-fail()
                        else 
                            shutdown-ok()

        return e.promise 

    put = (local, local-path, remote-path) ->

        e = __q.defer()
        conn = cnn.create-connection()
        conn = cnn.connect(conn, local)
        cnn.register-msg-handlers(conn)

        shutdown-ok = -> 
                conn.end()
                e.resolve()

        shutdown-fail = ->
                conn.end()
                e.reject(it)      


        conn.on 'ready', -> 
            conn.sftp (err, sftp) ->
                if err 
                    shutdown-fail()
                else 
                    sftp.fast-put local-path, remote-path, (err) ->
                        if err 
                            shutdown-fail()
                        else 
                            shutdown-ok()

        return e.promise

    open-terminal = (address) ->
       d = __q.defer()

       if address.access == 'ssh'
            args = [
                        "#{address.username}@#{address.hostname}"
                        "-p"
                        "#{address.port}"
                        ]

            pdeb "Executing command `ssh` #{args[0]}, #{args[1]}, #{args[2]}"

            ch2 = spawn 'ssh', args, stdio: 'inherit'

            ch2.on 'error', ->
                d.reject("Failed connection")

            ch2.on 'close', ->
                d.resolve("Exited from command line.")

            return d.promise

       if address.access == 'ftp'

            us  = address.username
            url = address.hostname
            pw  = require(address.credentials)[url][us]

            args = [
                        "-e"
                        lftp-script(us, pw, url)
                        ]

            pdeb "Executing command `lftp` #{args[0]}, #{args[1]}"
            cc = spawn 'lftp', args, stdio: \inherit

            cc.on 'error', ->
                d.reject("Failed connection")    

            cc.on 'close', ->
                d.resolve('Exited from ftp')

            return d.promise

       d.reject("Invalid #{address.access} specified as access mode.")
       return d.promise

    save = (what, options) ->
        d = __q.defer()

        if not options.in? and not options.to?
             d.reject("Sorry, invalid options for save")

        [ node, filename ]  = options.to / ':'

        if node  != 'local'

            if not options.in[node]?
                 d.reject("Sorry, #node does not exist")


            nn = options.in[node].path

            disp "Saving output to ftp://#{nn.hostname}:#filename"

            dd = setup-temporary-directory()

            fs.write-file "#dd/temp.json", (what), (err) ->

                if err 
                    d.reject("Problems writing #dd/temp.json")
                    return 

                us  = nn.username
                url = nn.hostname
                pw  = require(nn.credentials)[url][us]

                args = [
                            "-e"
                            lftp-script-put(us, pw, url, "#dd/temp.json", filename)
                            ]

                cc = spawn 'lftp', args

                cc.on 'error', ->
                    d.reject("Failed connection")    

                cc.on 'close', ->
                    d.resolve('Exited from ftp')

            return d.promise

        else 
            dirn = filename
            txt = what.text
            txt.to "#dirn/#{what.filename}"



    init = (data) -> 
       scope := data
  
    iface = { 
        get: get
        put: put
        save: save
        open-terminal: open-terminal
    }
  
    return iface
 
module.exports = _module()