{ namespace, task, build-tasks, run, run-local, run-local-safe, create-local, remove-local, zsh, bsh, sequence } = require('swiss-deploy-knife/lib/task')
{ print-as-table }                                                                               = require('swiss-deploy-knife/lib/print')
{ get, put, open-terminal, save, mirror, append }                                                = require('swiss-deploy-knife/lib/ssh')
{ create-lezione, create-esercitazione, create-comunicazione }                                   = require('swiss-deploy-knife/lib/jekyll')
{ fail } = require('swiss-deploy-knife/lib/actions')

shelljs = require('shelljs')

save-remotely = save

copy = (x) ->
  cmm = "echo '#x' | pbcopy"
  console.log  "Copying '#x' to the clipboard"
  shelljs.exec(cmm)


mzsh = (c) ->
        "zsh -l -c 'source .zshrc && #c'"

czsh = (c) ->
        "zsh -c 'source github/shellinit/common.zshrc && #c'"


home     = process.env.HOME
ssh-cred = "#home/.ssh/id_rsa"



setup-ubuntu-docker = '''
# DOCKER-VERSION 0.8.0
#
# Dockerfile created for staging and deploy infoweb-app


FROM cmfatih/nodejs

EXPOSE 80
EXPOSE 22

RUN npm install -g n
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install wget curl
'''

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
          port        : 22
          credentials : ssh-cred
          hosttype    : 'linux'
          access      : \ssh
          shell       : mzsh
          login: 
            directory   : '~/test'

    s2: 
        description: "Boot2docker box"

        path: 
          from        : \s1
          use         : 4444
          username    : "docker"
          hostname    : "localhost"
          port        : 2022
          credentials : ssh-cred
          hosttype    : 'linux'
          access      : \ssh
          login:
            shell       : bsh
            run-as-sudo : true
            directory   : '~/test/infoweb'

    # d1: 
    #     description: "Boot2docker on Mac"

    #     path: 
    #       from        : \s1
    #       use         : 2022
    #       username    : "docker"
    #       hostname    : "localhost"
    #       port        : "2022"
    #       credentials : ssh-cred
    #       hosttype    : 'linux'
    #       access      : \ssh
    #       shell       : bsh
    #       directory   : '~'

    # d2: 
    #     description: "Container 1 on Boot2docker"

    #     path:
    #       from        : \d1
    #       use         : 4444
    #       username    : "root"
    #       hostname    : "0.0.0.0"
    #       port        : "41150"
    #       credentials : ssh-cred
    #       hosttype    : 'linux'
    #       access      : \ssh
    #       login:
    #         shell       : bsh
    #         directory   : '~/test'          

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

    bonzo:
        description: "Mini farm"

        path: 

          username    : "zaccaria"
          hostname    : "192.168.0.103"
          port        : "22"
          credentials : ssh-cred
          hosttype    : 'linux'
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

            task 'env', 'prints current env, as seen by sk', ->
              console.log process.env

## Remember to upload:
#
# #!/bin/sh
# ./bin/ngrok $@ 
#
# as ngrok.sh

        namespace 'mac', 'applicable to this mac', { default-node: 's3'}, 
            task 'vagrant-check', {+show}, 'inspects a running instance of vagrant (local)', ->
              run @remote, [ "bash -l -c 'cd ~/docker/docker && vagrant status | grep default'" ]

        namespace 'local', 'these commands run only on local machine', { default-node: 's3root' },
            task 'install-semantic-angle', 'downloads SA from github and installs it in the local directory', ->
               shelljs.exec 'wget https://github.com/vzaccaria/semantic-angle/archive/master.zip'
               shelljs.exec 'mv master master.zip'
               shelljs.exec 'unzip *.zip'


        namespace 'hbomb', 'applicable to hbomb', { default-node: 's1' },

            task 'vagrant-check', 'inspects a running instance of vagrant', ->
              run @remote, [ "bash -l -c 'cd /data2/zaccaria && vagrant status | grep default'" ]


        namespace 'linux', 'general commands applicable to x86 hosts', { default-node: 's2' },

            task 'prepare-ngrok', 'Installs ngrok into target machine', ->
              run-local @remote, [
                                    "mkdir -p #local-bin-dir"
                                    "rm -f ngrok.zip"
                                    "rm -f ngrok"
                                    "wget https://dl.ngrok.com/linux_386/ngrok.zip"
                                    "wget http://www.vittoriozaccaria.net/deposit/ngrok.sh"
                                    "unzip ngrok.zip"
                                    "rm -f ngrok.zip"
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


        namespace 'infoweb', 'tasks associated with testing the infoweb project', {default-node: 's1'},

            task 'buildenv-manual', {+show}, "Shows manual steps to define a build environment", ->   
              s = """
              sudo DEBIAN_FRONTEND=noninteractive apt-get -y install curl
              sudo npm install -g grunt-cli sails n mocha forever LiveScript
              """
              console.log s

            task 'buildenv-showprereq', {+show}, "Installs curl and shows installation prerequisites after a clean vagrant installation", ->
              run-local @remote, "apt-get install curl", { +run-as-sudo }
              .then ~> 

                s = """
                    *** 
                    Setup svn: sudo vi ~/.subversion/servers -> store-passwords and store-plaintext-passwords = yes
                    Setup grok with task linux:prepare-ngrok

                    If the target machine is a docker host, copy and paste this into a Dockerfile:

                    # DOCKER-VERSION 0.8.0
                    #
                    # Dockerfile created for staging and deploy infoweb-app


                    FROM cmfatih/nodejs

                    EXPOSE 80
                    EXPOSE 22

                    RUN npm install -g n
                    RUN DEBIAN_FRONTEND=noninteractive apt-get -y install wget
                    """

                console.log s

            task 'buildenv-create', "Creates the environment for infoweb, using default-node data", ->
              create-local @remote 

            task 'buildenv-remove', "Removes the environment for infoweb, using default node data", ->
              remove-local @remote

            task 'buildenv-prepare', "Installs globally grunt, sails, n and node 0.10.13", ->
              run-local @remote, "npm install -g grunt-cli sails n mocha forever LiveScript", { +run-as-sudo }
              .then ~> run-local @remote, "n 0.10.13"

            task 'buildenv-default', {+show}, "Cleans up everything and prepares for a new installation. Launch after buildenv-showprereq ", ->
              sequence @, [ 'buildenv-remove', 'buildenv-create' ]


            task 'src-checkout', "Checks out repository in ~/test/infoweb", ->
              run-local @remote, 'svn co -q https://zaccaria@svn.ws.dei.polimi.it/multicube/trunk/devel/zaccaria/infoweb'

            task 'src-update', "Update repo in ~/test/infoweb", ->
              run-local @remote, 'svn update infoweb'

            task 'src-link-packages', "Executes `npm install` in ~/test/infoweb", ->

              run-local @remote          , 'npm install'                          , { sub-dir: 'infoweb'}
              .then ~> run-local @remote , 'npm install ansi-color optimist shelljs ansi-color-table express' , { sub-dir: 'infoweb' }
              .then ~> run-local @remote , 'npm install'                          , { sub-dir: 'infoweb/node_modules/sails' }

            task 'src-compile',   "Executes `grunt deploy` in ~/test/infoweb",   ->
              run-local @remote, 'grunt deploy', { sub-dir: 'infoweb'}

            task 'src-default', { +show }, "After buildenv-default, deploy from svn and finalize source code with this command", ->
              sequence @, [ 'src-checkout', 'src-link-packages', 'src-compile' ]


            task 'src-default-fast', "When source is already deployed, same as above but use only update from svn", ->
              sequence @, [ 'src-update', 'src-link-packages', 'src-compile' ]

            # ----

            task 'test-be2', -> 
              run-local-safe @remote, './scripts/be2-test', { sub-dir: 'infoweb', +silent }
              .then ~> append it, { to: "w1:data/iwtest-be2.json", in: @nodes, first: 5 }

            task 'test-be',  -> 
              run-local-safe @remote, './scripts/be-test', { sub-dir: 'infoweb', +silent }
              .then ~> append it, { to: "w1:data/iwtest-be.json", in: @nodes, first: 5 }

            task 'test-fe',  -> 
              run-local-safe @remote, './scripts/fe-test', { sub-dir: 'infoweb', +silent }
              .then ~> append it, { to: "w1:data/iwtest-fe.json", in: @nodes, first: 5 }

            task 'test-default', { +show }, "Executes tests on current environment",   ->
              sequence @, [ 'test-be', 'test-be2', 'test-fe', 'test-e2e-default' ]


            # ---

            task 'stage-and-test-default', {+show}, "(Nightly) Wipes everything, builds and tests (complete regression test)", ->
              sequence @, [
                            'buildenv-default'
                            'src-default'
                            'test-default'                           
                            ]


            # ----

            task 'test-e2e-start', "Starts app in test mode",   ->
              run-local @remote, 'NODE_TEST=true forever start app.js', { sub-dir: 'infoweb/infoweb'}

            task 'test-e2e-stop', "Stops app in test mode",   ->
              run-local @remote, 'NODE_TEST=true forever stop app.js', { sub-dir: 'infoweb/infoweb'}

            task 'test-e2e-engage', "End to end test",   ->
              run-local-safe @remote, './scripts/e2e-test', { sub-dir: 'infoweb', +silent }
              .then ~> append it, { to: "w1:data/iwtest-e2e.json", in: @nodes, first: 5 }
              .then ~> run-local @remote, 'killall phantomjs'

            task 'test-e2e-human-engage', "End to end test",   ->
              run-local @remote, './scripts/e2e-test-human', { sub-dir: 'infoweb', +silent }
              .then ~> run-local @remote, 'killall phantomjs'

            task 'test-e2e-default', "Starts test server, tests e2e and shutsdown test server",   ->
              sequence @, ['test-e2e-start', 'test-e2e-engage', 'test-e2e-stop']

            task 'test-e2e-human-default', "Starts test server, tests e2e and shutsdown test server",   ->
              sequence @, ['test-e2e-start', 'test-e2e-human-engage', 'test-e2e-stop']
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


        namespace 'render', 'general commands to render to blender' {default-node: 's2'}, 

            task 'put', 'Copies files to hbomb', ->
              code = (shelljs.exec "scp #{@args.command} zaccaria@hbomb.elet.polimi.it:/data2/zaccaria/vagrant/tmp.blend").code
              if code == 0
                run @remote, "cp '/vagrant/vagrant/tmp.blend' ~/blender-test/blend"
              else 
                console.log "Sorry, cannot find file."
                fail()

            task 'render', ->
              run @remote, "cd ~/blender-test && blender -noaudio -b ./blend/tmp.blend -o //file -F JPEG -x 1 -f 1"

            task 'get', 'Gets files from hbomb', ->
              run @remote, "cp '/home/vagrant/blender-test/blend/file0001.jpg' /vagrant/vagrant/result.jpg"
              .then -> shelljs.exec "scp zaccaria@hbomb.elet.polimi.it:/data2/zaccaria/vagrant/result.jpg ."

            task 'complete', ->
              sequence @, [ 'put', 'render', 'get' ]

        namespace 'bz-render', 'general commands to render to blender' {default-node: 'bonzo'}, 

            task 'put', 'Copies files to bonzo', ->
              code = (shelljs.exec "scp #{@args.command} zaccaria@192.168.0.103:/home/zaccaria/blender-tests/blend/tmp.blend").code
              if code != 0
                console.log "Sorry, cannot find file."
                fail()

            task 'render', ->
              run @remote, "cd ~/blender-tests && blender -noaudio -b ./blend/tmp.blend -o //file -F JPEG -x 1 -f 1"

            task 'get', 'Gets files from bonzo', ->
              shelljs.exec "scp  zaccaria@192.168.0.103:/home/zaccaria/blender-tests/blend/file0001.jpg ./result.jpg"

            task 'complete', ->
              sequence @, [ 'put', 'render', 'get' ]              

            ...
        ]
        

module.exports.nodes = nodes
module.exports.namespace = ns 


            # task 'sysg', "Copies syslog locally", ->
            #   get @remote, '/var/log/syslog', './syslog'

            # task 'sysg-ls', "Copies syslog locally and launches log stash", ->
            #   get @remote, '/var/log/syslog', '/tmp/syslog'
            #   .then -> run-ls-syslog '/tmp/syslog'








