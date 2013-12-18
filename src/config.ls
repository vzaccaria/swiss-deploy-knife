{ namespace, task, build-tasks, run, run-local, create-local, remove-local, zsh, bsh, sequence } = require('swiss-deploy-knife/lib/task')
{ print-as-table }                                                                          = require('swiss-deploy-knife/lib/print')
{ get, put, open-terminal, save, mirror }                                                   = require('swiss-deploy-knife/lib/ssh')
{ create-lezione, create-esercitazione, create-comunicazione }                              = require('swiss-deploy-knife/lib/jekyll')

save-remotely = save

copy = (x) ->
  cmm = "echo '#x' | pbcopy"
  console.log  "Copying '#x' to the clipboard"
  shelljs.exec(cmm)


mzsh = (c) ->
        "zsh -l -c 'source .zshrc && #c'"


home     = process.env.HOME
ssh-cred = "#home/.ssh/id_rsa"

nodes = 
    w1:
        description: "Website at www.vittoriozaccaria.net"

        path: 

          username    : "vittoriozaccaria.net"
          hostname    : "217.64.195.216"
          credentials : "#home/.ssh/sftp_credentials.js"
          access      : \ftp
          
        save-to:   "data"

    s1:
        description: "Hbomb"

        path: 

          username    : "zaccaria"
          hostname    : "hbomb.elet.polimi.it"
          port        : "22"
          credentials : ssh-cred
          hosttype    : 'linux'
          access      : \ssh
          shell       : bsh
          directory   : '~'

    s2: 
        description: "Vagrant box"

        path: 
          from        : \s1
          use         : 4444
          username    : "vagrant"
          hostname    : "127.0.0.1"
          port        : "2222"
          credentials : ssh-cred
          hosttype    : 'linux'
          access      : \ssh
          login:
            shell       : bsh
            run-as-sudo : true
            directory   : '~/test/infoweb'

    s3:
        description: "Macbook"

        path: 

          username    : "zaccaria"
          hostname    : "localhost"
          port        : "22"
          credentials : ssh-cred
          hosttype    : 'mac'
          access      : \ssh
          login:
            shell       : mzsh
            run-as-sudo : false
            directory   : '~/test/infoweb'

    s3root:
        description: "Macbook"

        path: 

          username    : "zaccaria"
          hostname    : "localhost"
          port        : "22"
          credentials : ssh-cred
          hosttype    : 'mac'
          access      : \ssh
          login:
            shell       : mzsh
            run-as-sudo : false
            directory   : '~'

    default: 's3'


local-bin-dir = 'bin'

if require('os').hostname() is 'hbomb'
  delete nodes['s2'].path.from
  delete nodes['s2'].path.use

ns = build-tasks [
        namespace 'general', 'general commands applicable to almost all access modes',

            task 'cmd', "Executes a command specified with -c `command`", ->
              run @remote, @args.command

            task 'dfj',  'inspects disk quotas', -> 
              run-local @remote, 'df-json' , { +silent }
              .then ~> JSON.parse it
              .then ~> 
                opts = 
                  sparkly: ['percent', 'blocks']
                  remove:  ['filesystem', 'used', 'available']
                print-as-table(@remote, it, opts)

            task 'ssh', 'launches an ssh term on the remote node', ->
              open-terminal @remote 

## Remember to upload:
#
# #!/bin/sh
# ./bin/ngrok $@ 
#
# as ngrok.sh

        namespace 'mac', 'applicable to this mac', { default-node: 's3'}, 
            task 'vagrant-check', 'inspects a running instance of vagrant (local)', ->
              run @remote, [ "bash -l -c 'cd ~/docker/docker && vagrant status | grep default'" ]

        namespace 'hbomb', 'applicable to hbomb', { default-node: 's1' },

            task 'vagrant-check', 'inspects a running instance of vagrant', ->
              run @remote, [ "bash -l -c 'cd /data2/zaccaria && vagrant status | grep default'" ]


        namespace 'linux', 'general commands applicable to x86 hosts', { default-node: 's2' },

            task 'prepare-ngrok', 'Installs ngrok into target machine', ->
              run-local @remote, [
                                    "mkdir -p #local-bin-dir"
                                    "rm ngrok.zip"
                                    "rm ngrok"
                                    "wget https://dl.ngrok.com/linux_386/ngrok.zip"
                                    "wget http://www.vittoriozaccaria.net/deposit/ngrok.sh"
                                    "unzip ngrok.zip"
                                    "rm ngrok.zip"
                                    "mv ngrok #local-bin-dir"
                                    "mv ngrok.sh #local-bin-dir"
                                    ]

            task 'prepare-forever', 'Installs forever on target machine', ->
              run-local @remote, "npm install -g n forever"

            ...

        namespace 'jekyll', 'jekyll website tasks', {default-node: 's3'},

            task 'lezione', "Creates a post for a lezione, use -c 'tag1,tag2,...' for tags", ->
              post = create-lezione @args.tags
              # console.log save-remotely, create-lezione
              save post, { to: "local:/Users/zaccaria/short/website/_posts/", in: @nodes }
              copy "vi /Users/zaccaria/short/website/_posts/#{post.filename}"

            task 'esercitazione', "Creates a post for an esercitazione, use -c 'tag1,tag2,...' for tags", ->
              post = create-esercitazione @args.tags
              # console.log save-remotely, create-lezione
              save post, { to: "local:/Users/zaccaria/short/website/_posts/", in: @nodes }
              copy "vi /Users/zaccaria/short/website/_posts/#{post.filename}"

            task 'comunicazione', "Creates a post for a comunicazione, use -c 'tag1,tag2,...' for tags", ->
              post = create-comunicazione @args.tags
              # console.log save-remotely, create-lezione
              save post, { to: "local:/Users/zaccaria/short/website/_posts/", in: @nodes }
              copy "vi /Users/zaccaria/short/website/_posts/#{post.filename}"

            task 'deploy', "Deploy the website", ->
              run-local @remote, "cd /Users/zaccaria/short/website && make", { +silent }
              .then ~> mirror { from: "local:/Users/zaccaria/short/website/_site", to: "w1:.", in: @nodes }

            ...


        namespace 'infoweb', 'tasks associated with testing the infoweb project', {default-node: 's2'},

            task 'buildenv-create', "Creates the environment for infoweb, using default-node data", ->
              create-local @remote 

            task 'buildenv-remove', "Removes the environment for infoweb, using default node data", ->
              remove-local @remote

            task 'buildenv-prepare', "Installs globally grunt, sails, n and node 0.10.13", ->
              run-local @remote, "npm install -g grunt-cli sails n mocha forever", { +run-as-sudo }
              .then ~> run-local @remote, "n 0.10.13"

            # ----

            task 'src-checkout', "Checks out repository in ~/test/infoweb", ->
              run-local @remote, 'svn co -q https://zaccaria@svn.ws.dei.polimi.it/multicube/trunk/devel/zaccaria/infoweb'

            task 'src-update', "Update repo in ~/test/infoweb", ->
              run-local @remote, 'svn update infoweb'

            task 'src-link-packages', "Executes `npm install` in ~/test/infoweb", ->

              run-local @remote          , 'npm install'                          , { sub-dir: 'infoweb'}
              .then ~> run-local @remote , 'npm install shelljs ansi-color-table' , { sub-dir: 'infoweb' }
              .then ~> run-local @remote , 'npm install'                          , { sub-dir: 'infoweb/node_modules/sails' }

            task 'src-compile',   "Executes `grunt deploy` in ~/test/infoweb",   ->
              run-local @remote, 'grunt deploy', { sub-dir: 'infoweb'}

            # ----

            task 'test-be2', -> 
              run-local @remote, './scripts/be2-test', { sub-dir: 'infoweb', +silent }
              .then ~> save it, { to: "w1:data/iwtest-be2.json", in: @nodes }

            task 'test-be',  -> 
              run-local @remote, './scripts/be-test', { sub-dir: 'infoweb', +silent }
              .then ~> save it, { to: "w1:data/iwtest-be.json", in: @nodes }

            task 'test-fe',  -> 
              run-local @remote, './scripts/fe-test', { sub-dir: 'infoweb', +silent }
              .then ~> save it, { to: "w1:data/iwtest-fe.json", in: @nodes }

            task 'test-all', "Executes tests",   ->
              sequence @, [ 'test-be', 'test-be2', 'test-fe' ]


            # ---

            task 'test-fast-stage', "Updates and compiles", ->
              sequence @, [
                            'src-update'
                            'src-link-packages'
                            'src-compile'                           
                            ]

            task 'test-after-fast-staging', "Updates remote repo, runs `deploy` and `test`", ->
              sequence @, [ 
                            'test-fast-stage'
                            'test-all'
                            ]

            task 'test-complete-stage', "Checks out and compiles", ->
                          [
                            'buildenv-remove', 
                            'buildenv-create', 
                            'src-checkout', 
                            'src-link-packages', 
                            'src-compile'               
                            ]

            task 'test-after-complete-staging', "Cleans up everything and reinstall to test", ->
              sequence @, [ 
                            'test-fast-stage'
                            'test-all'
                            ]

            # ----

            task 'test-e2e-start', "Starts app in test mode",   ->
              run-local @remote, 'NODE_TEST=true forever start app.js', { sub-dir: 'infoweb/infoweb'}

            task 'test-e2e-stop', "Stops app in test mode",   ->
              run-local @remote, 'NODE_TEST=true forever stop app.js', { sub-dir: 'infoweb/infoweb'}

            task 'test-e2e-engage', "End to end test",   ->
              run-local @remote, './scripts/e2e-test', { sub-dir: 'infoweb', +silent }
              .then ~> save it, { to: "w1:data/iwtest-e2e.json", in: @nodes }
              .then ~> run-local @remote, 'killall phantomjs'

            task 'test-e2e', "Starts test server, tests e2e and shutsdown test server",   ->
              sequence @, ['test-e2e-start', 'test-e2e-engage', 'test-e2e-stop']


            # ----

            task 'prod-start', "Starts app in production mode",   ->
              run-local @remote, 'NODE_ENV=production forever start app.js', { sub-dir: 'infoweb/infoweb' }

            task 'prod-stop', "Stops app in production  mode",   ->
              run-local @remote, 'NODE_ENV=production forever stop app.js', { sub-dir: 'infoweb/infoweb'}

            task 'prod-openport', "Opens 80 through ngrok", ->
              auth = require('/Users/zaccaria/.ssh/ngrok_credentials.js').token
              run-local @remote, [ "forever start -c 'bash' #local-bin-dir/ngrok.sh -authtoken #auth -subdomain=vz-infoweb-prod  -proto=http -log='stdout' 80 " ]

            task 'prod-lift', "Lift app and start ngrok", ->
              sequence @, ['prod-start', 'prod-openport']


            # ----

            task 'forever-stopall', "Close app", ->
              run-local @remote, "forever stopall"

            task 'forever-list', 'List forever processes', ->
              run-local @remote, "forever list" 

            task 'ssh', 'Launches an ssh term on the remote node', ->
              open-terminal @remote 

            ...
        ]
        

module.exports.nodes = nodes
module.exports.namespace = ns 


            # task 'sysg', "Copies syslog locally", ->
            #   get @remote, '/var/log/syslog', './syslog'

            # task 'sysg-ls', "Copies syslog locally and launches log stash", ->
            #   get @remote, '/var/log/syslog', '/tmp/syslog'
            #   .then -> run-ls-syslog '/tmp/syslog'








