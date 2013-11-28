cwd = process.cwd()
debug = false 

if debug
  { namespace, task, build-tasks, run, get, print-as-table, run-ls-syslog } = require("#{__dirname}/../index.js")
else
  { namespace, task, build-tasks, run, get, print-as-table, run-ls-syslog } = require('swiss-deploy-knife')

nodes = 
    web:
        description:            "Website at www.vittoriozaccaria.net"
        path: { username: "www.vittoriozaccaria.net", hostname: "www.vittoriozaccaria.net", port: 22 }
        access:                 \sftp 
        local-dir:              "xyz"
        remote-dir:             "uvw"

    s1:
        description: "Hbomb"
        path: { username: "zaccaria" , hostname: "hbomb.elet.polimi.it" , port: "22" , credentials: '/Users/zaccaria/.ssh/id_rsa' }
        access: \ssh

    s2: 
        description: "Vagrant box"
        path: { from: \s1, use: 4444, username: "vagrant", hostname: "127.0.0.1", port: "2222", credentials: '/Users/zaccaria/.ssh/id_rsa' }
        access: \ssh


    default: 's1'


ns = build-tasks [
        namespace 'general', 'general commands applicable to almost all access modes',

            # Use bound functions ~> inside tasks..
            task 'top', 'inspects processes', -> 
              run @local, 'top -b -n 1 | head -n 12'

            task 'df',  'inspects disk quotas', -> 
              run @local, 'df'

            task 'free', ->
              run @local, 'free'

            task 'cmd', "Executes a command specified with -c `command`", ->
              run @local, @args.command

            task 'sysg', "Copies syslog locally", ->
              get @local, '/var/log/syslog', './syslog'

            task 'sysg-ls', "Copies syslog locally and launches log stash", ->
              get @local, '/var/log/syslog', '/tmp/syslog'
              .then -> run-ls-syslog '/tmp/syslog'

            task 'npm', "Executes an npm command", ->
              run @local, "npm #{@args.command}"

            task 'snpm', "Executes an npm command with sudo", ->
              run @local, "sudo npm #{@args.command}"

            task 'dfj',  'inspects disk quotas', -> 
              run @local, 'df-json', { +silent }
              .then -> JSON.parse it
              .then -> 
                opts = 
                  sparkly: ['percent']
                  remove:  ['filesystem']
                print-as-table(it, opts)

            ...

        namespace 'infoweb', 'tasks associated with the infoweb project',
            task 'deploy', "Checks out repository in deployment space"   ->
            task 'test',   "Builds and tests project"   ->
            ...
        ]
        

   #  'infoweb': ->
   #      task 'stage', ->
   #          svn.login ->
   #              svn.checkout ->
   #                  grunt.deploy ->

   #      task 'test', ->
   #          run.task('stage'), ->
   #              grunt.test()

   #      task 'run', ->
   #          run.task('stage:staging-box1') ->
   #              run.task('test:staging-box1') ->
   #                  ngrok.expose(4043,....)
   #                  grunt.production.run

   # 'web': ->

   #      task 'deploy', (node) ->
   #          sftp.login (node.credentials.username, node.credentials.password) ->
   #              sftp.copy ->
   #                  grunt.deploy ->



# Example usage
#
#
# sk infoweb:deploy staging-box1
# sk infoweb:run staging-box2
# sk top staging-box2

# Example usage of APIs
#
#    task 'disk', (done) -> run 'df -h', done
#    task 'top',  (done) -> run 'top -b -n 1 | head -n 12', done
#    task 'who',  (done) -> run 'who', done
#    task 'node', (done) -> run 'ps -eo args | grep node | grep -v grep', done
#    task 'free', (done) -> run 'free', done
#
#    task 'all', (done) ->
#        sequence 'top', 'free', 'disk', 'node', done
#
#    # display last 100 lines of application log
#    task 'log', ->
#        run "tail -n 100 #{roco.sharedPath}/log/#{roco.env}.log"



module.exports.nodes = nodes
module.exports.namespace = ns 











