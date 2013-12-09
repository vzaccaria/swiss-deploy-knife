{ namespace, task, build-tasks, run, bsh, sequence } = require('swiss-deploy-knife/lib/task')
{ print-as-table }                                   = require('swiss-deploy-knife/lib/print')
{ get, put, open-terminal, save }                    = require('swiss-deploy-knife/lib/ssh')
{ create-lezione, create-esercitazione }             = require('swiss-deploy-knife/lib/jekyll')

save-remotely = save

copy = (x) ->
  cmm = "echo '#x' | pbcopy"
  console.log  "Copying '#x' to the clipboard"
  shelljs.exec(cmm)


nodes = 
    w1:
        description:            "Website at www.vittoriozaccaria.net"

        path: 
          username: "vittoriozaccaria.net"
          hostname: "217.64.195.216"
          credentials: '/Users/zaccaria/.ssh/sftp_credentials.js'
          access:    \ftp 
          
        save-to:   "data"

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

    s3:
        description: "Macbook"

        path: 
          username: "zaccaria" 
          hostname: "localhost" 
          port: "22" 
          credentials: '/Users/zaccaria/.ssh/id_rsa'
          hosttype: 'mac' 
          access: \ssh

    default: 's2'

x = (c) ->
  bsh "cd ~/test/infoweb/infoweb && sudo #c"

s = (c) ->
  bsh "cd ~/test/infoweb/infoweb/node_modules/sails && sudo #c"

f = (c) ->
  bsh "cd ~/test/infoweb/infoweb && sudo forever #c"

local-bin-dir = 'bin'

b = (c) ->
  "cd #local-bin-dir && #c"


ns = build-tasks [
        namespace 'general', 'general commands applicable to almost all access modes',

            # Use bound functions ~> inside tasks..
            task 'top', 'inspects processes', -> 
              run @remote, 'top -b -n 1 | head -n 12'

            task 'df',  'inspects disk quotas', -> 
              run @remote, 'df'

            task 'free', ->
              run @remote, 'free'

            task 'cmd', "Executes a command specified with -c `command`", ->
              run @remote, @args.command

            task 'sysg', "Copies syslog locally", ->
              get @remote, '/var/log/syslog', './syslog'

            # task 'sysg-ls', "Copies syslog locally and launches log stash", ->
            #   get @remote, '/var/log/syslog', '/tmp/syslog'
            #   .then -> run-ls-syslog '/tmp/syslog'

            task 'npm', "Executes an npm command", ->
              run @remote, "npm #{@args.command}"

            task 'snpm', "Executes an npm command with sudo", ->
              run @remote, "sudo npm #{@args.command}"

            task 'dfj',  'inspects disk quotas', -> 
              run @remote, 'source .zshrc && df-json' , { +silent }
              .then ~> JSON.parse it
              .then ~> 
                opts = 
                  sparkly: ['percent', 'blocks']
                  remove:  ['filesystem', 'used', 'available']
                print-as-table(@remote, it, opts)

            task 'ssh', 'launches an ssh term on the remote node', ->
              open-terminal @remote 

            task 'vg1', 'inspects a running instance of vagrant', ->
              run @remote, [ "bash -l -c 'cd /data2/zaccaria && vagrant status | grep default'" ]

            task 'vg2', 'inspects a running instance of vagrant (local)', ->
              run @remote, [ "bash -l -c 'cd ~/docker/docker && vagrant status | grep default'" ]

            task 'seq', 'sequence test', ->
              sequence @, [ "df", "dfj" ]


## Remember to upload:
#
# #!/bin/sh
# ./bin/ngrok $@ 
#
# as ngrok.sh

            task 'prepare-ngrok', 'Installs ngrok into target machine', ->
              run @remote, [
                                "mkdir -p #local-bin-dir"
                                b "wget https://dl.ngrok.com/linux_386/ngrok.zip"
                                b "unzip ngrok.zip"
                                b "rm ngrok.zip"
                                ]

            task 'prepare-forever', 'Installs forever on target machine', ->
              run @remote, "sudo npm install -g n forever"

            task 'qe', 'Expose a specific port on the web', ->
              run @remote, [ 
                              "sudo forever start -c 'bash' #local-bin-dir/ngrok.sh -proto=http -log='stdout' #{@args.command}"
                              "sudo forever logs 0"
                              "sudo forever logs 0"
                              "sudo forever logs 0"
                              ]


            task 'eq', 'End exposure', ->
              run @remote, "sudo forever stop 0"

            task 'fl', 'List forever processes', ->
              run @remote, f "list" 
            ...

        namespace 'j', 'jekyll website tasks',

            task 'lez', "Creates a post for a lezione, use -c 'tag1,tag2,...' for tags", ->
              post = create-lezione @args.command
              # console.log save-remotely, create-lezione
              save post, { to: "local:/Users/zaccaria/short/website/_posts/", in: @nodes }
              copy "vi /Users/zaccaria/short/website/_posts/#{post.filename}"

            task 'ese', "Creates a post for an esercitazione, use -c 'tag1,tag2,...' for tags", ->
              post = create-esercitazione @args.command
              # console.log save-remotely, create-lezione
              save post, { to: "local:/Users/zaccaria/short/website/_posts/", in: @nodes }
              copy "vi /Users/zaccaria/short/website/_posts/#{post.filename}"

            ...

        namespace 'iwtest', 'tasks associated with testing the infoweb project',

            task 'prepare', "Installs globally grunt, sails, n and node 0.10.13", ->
              run @remote, "sudo npm install -g grunt-cli sails n mocha forever"
              .then ~> run @remote, "sudo n 0.10.13"

            task 'cleanup', "Cleans up remote test directories", ->
              run @remote, [
                              bsh 'sudo rm -rf ~/test/infoweb'

                              ]
            task 'preprov', "Creates the test directories", ->
              run @remote, [
                              bsh 'sudo mkdir -p ~/test'
                              bsh 'sudo mkdir -p ~/test/infoweb'
                              ]

            task 'prov', "Checks out repository in ~/test/infoweb", ->
              run @remote, [ 
                              bsh 'cd ~/test/infoweb && sudo svn co -q https://zaccaria@svn.ws.dei.polimi.it/multicube/trunk/devel/zaccaria/infoweb'
                              ]

            task 'update', "Update repo in ~/test/infoweb", ->
              run @remote, [ 
                              bsh 'cd ~/test/infoweb && sudo svn update -q https://zaccaria@svn.ws.dei.polimi.it/multicube/trunk/devel/zaccaria/infoweb'
                              ]


            task 'install', "Executes `npm install` in ~/test/infoweb", ->
              run @remote, [
                              x 'npm install'
                              ]

            task 'build',   "Executes `grunt deploy` in ~/test/infoweb",   ->
              run @remote, x('grunt deploy')

            task 'setup-tests', "Installs dependencies associated with tests (e.g., shelljs)", ->
              run @remote, [ 
                              x 'npm install shelljs'
                              x 'npm install ansi-color-table'
                              s 'npm install'
                              ]

            task 'be2-test', -> 
              run @remote, x './scripts/be2-test', {+silent}
              .then ~> save it, { to: "w1:data/iwtest-be2.json", in: @nodes }

            task 'be-test',  -> 
              run @remote, x './scripts/be-test', {+silent}
              .then ~> save it, { to: "w1:data/iwtest-be.json", in: @nodes }

            task 'fe-test',  -> 
              run @remote, x './scripts/fe-test', {+silent}
              .then ~> save it, { to: "w1:data/iwtest-fe.json", in: @nodes }

            task 'test', "Executes tests",   ->
              sequence @, [ 'be-test', 'be2-test', 'fe-test' ]

            task 'start', "Starts app in daemon mode",   ->
              run @remote, f 'start infoweb/app.js'

            task 'stop', "Stops app in daemon mode",   ->
              run @remote, f 'stop infoweb/app.js'

            task 'faststage', "Updates remote repo, runs `deploy` and `test`", ->
              sequence @, ['update', 'build', 'test']

            ...
        ]
        

module.exports.nodes = nodes
module.exports.namespace = ns 











