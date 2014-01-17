_               = require('underscore')
_.str           = require('underscore.string');
moment          = require 'moment'
color           = require('ansi-color').set
__q             = require('q')
os              = require('os')
cl              = require('clark')
ut              = require('utf-8')
winston         = require('winston')


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




surl-get = (str) ->
    [ node-name, node-path ]    = str / ':'
    if not node-path?
        node-path = node-name
        node-name = 'local'
    return [ node-name, node-path ]

lftp-script-put = (us, pw, url, f, r) -> 
    """set ftp:ssl-allow false; open ftp://#us:#pw@#url; put #f -o #r; bye;"""

lftp-script-get = (us, pw, url, f, r) -> 
    """set ftp:ssl-allow false; open ftp://#us:#pw@#url; get #f -o #r; bye;"""

lftp_opts = "--reverse --ignore-time --verbose=1 --use-cache --allow-chown --allow-suid --no-umask --parallel=2 --exclude-glob .svn"

lftp-script-mirror = (us, pw, url, f, t) -> 
    """set ftp:ssl-allow false; open ftp://#us:#pw@#url; mirror #{lftp_opts} #{f} #{t}; bye;"""

_module = ->

    var scope 

    @child_process = require('child_process')
    @shelljs       = require('shelljs')
    @cnn           = require('./connect')
    @fs            = require 'fs'

    @setup-temporary-directory = ->
        name = "tmp_#{moment().format('HHmmss')}_tmp"
        dire = "#{otm}/#{name}" 
        shelljs.mkdir '-p', dire
        return dire

    @remove-temporary-directory = (dir) ->
        shelljs.rm '-rf', dir 

    @get-credentials = (credentials, url, user) ->
            return require(credentials)[url][user]

    append = (value, options) ->
        value = JSON.parse(value)

        combine = ->
            res = 
                | _.is-array(it) => [ value ] ++ it
                | _ => [ value, it ]

            res = 
                | options.filterAll? => res 
                | options.first? => _.first(res, options.first)
                | _ => _.first(res, 25)

            return res

        opt = { from: options.to, in: options.in }

        logt = -> 
            # console.log JSON.stringify(it, null, 4)
            # disp-ko(typeof it)
            return it

        p = load(opt).then(logt).then(combine).then(logt).then(->save(it, options))
        p.fail(-> save(value, options))



    open-terminal = (address) ->
       d = __q.defer()

       if address.access == 'ssh'
            args = [
                        "#{address.username}@#{address.hostname}"
                        "-p"
                        "#{address.port}"
                        ]

            pdeb "Executing command `ssh` #{args[0]}, #{args[1]}, #{args[2]}"

            ch2 = child_process.spawn 'ssh', args, stdio: 'inherit'

            ch2.on 'error', ->
                d.reject("Failed connection")

            ch2.on 'close', ->
                d.resolve("Exited from command line.")

            return d.promise

       if address.access == 'ftp'

            us  = address.username
            url = address.hostname
            pw  = get-credentials(address.credentials, url, us)

            args = [
                        "-e"
                        lftp-script(us, pw, url)
                        ]

            pdeb "Executing command `lftp` #{args[0]}, #{args[1]}"
            cc = child_process.spawn 'lftp', args, stdio: \inherit

            cc.on 'error', ->
                d.reject("Failed connection")    

            cc.on 'close', ->
                d.resolve('Exited from ftp')

            return d.promise

       d.reject("Invalid #{address.access} specified as access mode.")
       return d.promise

    mirror = (options) ->
        d = __q.defer()

        if not options.from? or not options.to? or not options.in?
             d.reject("Sorry, invalid options for save")
        else 
             [ local, frm ]    = options.from / ':'
             [ node, dirname ] = options.to / ':'

             if local != 'local'
                     d.reject("Sorry, mirror at the moment accepts only one remote destination")
                     return d.promise

             if not options?.in?[node]?.path?.access? == 'ftp'
                     d.reject("Sorry, #node does not exist or it does not have ftp access")
             else 
                nn = options.in[node].path
                us  = nn.username
                url = nn.hostname
                pw  = get-credentials(nn.credentials, url, us)
                args = [
                            "-e"
                            lftp-script-mirror(us, pw, url, frm, dirname)
                            ]
                pdeb "Executing command `lftp` #{args[0]}, #{args[1]}"
                cc = child_process.spawn 'lftp', args, stdio: \inherit 
                cc.on 'error', ->
                    d.reject("Failed connection")    

                cc.on 'close', ->
                    d.resolve('Exited from ftp') 

        return d.promise      
     
    get-as-sftp-node = (node, data) ->
        if not data[node]? or not data[node].path.access == 'ftp'
            return null
        else
            return data[node].path

    load = (options) ->
        d = __q.defer()

        if not options.in? or not options.from?
             d.reject("Sorry, invalid options for load")
        else
            [ node, filename ] = surl-get(options.from)

            if node  != 'local'

                node-coords = get-as-sftp-node(node, options.in)

                if not node-coords?
                     d.reject("Sorry, #node does not exist or it does not have ftp access")
                else
                    us  = node-coords.username
                    url = node-coords.hostname
                    dd  = setup-temporary-directory()
                    pw  = get-credentials(node-coords.credentials, url, us)

                    args = [
                                "-e"
                                lftp-script-get(us, pw, url, filename, "#dd/temp.json")
                                ]

                    cc = child_process.spawn 'lftp', args                

                    cc.on 'error', ->
                        remove-temporary-directory(dd)
                        d.reject("Failed connection")    

                    cc.on 'close', ->
                        dta = shelljs.cat("#dd/temp.json")
                        remove-temporary-directory(dd)
                        try
                            data = JSON.parse(dta)
                        catch error
                            d.reject(error)
                            return
                        d.resolve(data)

            else 
                dta = shelljs.cat(filename)
                data = JSON.parse(dta)
                d.resolve(data)


        return d.promise

    save = (what, options) ->
        d = __q.defer()

        if not options.in? or not options.to?
             d.reject("Sorry, invalid options for save")
        else 
            [ node, filename ] = surl-get(options.to)
            pdeb "Saving to #node - #filename"
            if node  != 'local'

                node-coords = get-as-sftp-node(node, options.in)

                if not node-coords?
                     d.reject("Sorry, #node does not exist or it does not have ftp access")
                else

                disp "Saving output to ftp://#{node-coords.hostname}:#filename"

                dd = setup-temporary-directory()

                fs.write-file "#dd/temp.json", (JSON.stringify(what, null, 4)), (err) ->

                    if err 
                        d.reject("Problems writing #dd/temp.json")
                        return 

                    us  = node-coords.username
                    url = node-coords.hostname
                    pw  = get-credentials(node-coords.credentials, url, us)

                    args = [
                                "-e"
                                lftp-script-put(us, pw, url, "#dd/temp.json", filename)
                                ]

                    cc = child_process.spawn 'lftp', args

                    cc.on 'error', ->
                        remove-temporary-directory(dd)
                        d.reject("Failed connection")    

                    cc.on 'close', ->
                        remove-temporary-directory(dd)
                        d.resolve('Exited from ftp')


            else 
                dirn = filename
                txt = what.text
                txt.to "#dirn/#{what.filename}"
                d.resolve("Saved to file")

        return d.promise        


    inner-module = ->
      return root

    init = (data) -> 
       scope := data
  
    iface = { 
        inner-module: inner-module
        load: load
        save: save
        append: append
        mirror: mirror
        open-terminal: open-terminal
    }
  
    return iface
 
module.exports = _module()