(function(){
  var cwd, debug, ref$, namespace, task, buildTasks, run, get, printAsTable, runLsSyslog, nodes, ns;
  cwd = process.cwd();
  debug = false;
  if (debug) {
    ref$ = require(__dirname + "/../index.js"), namespace = ref$.namespace, task = ref$.task, buildTasks = ref$.buildTasks, run = ref$.run, get = ref$.get, printAsTable = ref$.printAsTable, runLsSyslog = ref$.runLsSyslog;
  } else {
    ref$ = require('swiss-deploy-knife'), namespace = ref$.namespace, task = ref$.task, buildTasks = ref$.buildTasks, run = ref$.run, get = ref$.get, printAsTable = ref$.printAsTable, runLsSyslog = ref$.runLsSyslog;
  }
  nodes = {
    web: {
      description: "Website at www.vittoriozaccaria.net",
      path: {
        username: "www.vittoriozaccaria.net",
        hostname: "www.vittoriozaccaria.net",
        port: 22
      },
      access: 'sftp',
      localDir: "xyz",
      remoteDir: "uvw"
    },
    s1: {
      description: "Hbomb",
      path: {
        username: "zaccaria",
        hostname: "hbomb.elet.polimi.it",
        port: "22",
        credentials: '/Users/zaccaria/.ssh/id_rsa'
      },
      access: 'ssh'
    },
    s2: {
      description: "Vagrant box",
      path: {
        from: 's1',
        use: 4444,
        username: "vagrant",
        hostname: "127.0.0.1",
        port: "2222",
        credentials: '/Users/zaccaria/.ssh/id_rsa'
      },
      access: 'ssh'
    },
    'default': 's1'
  };
  ns = buildTasks([
    namespace('general', 'general commands applicable to almost all access modes', task('top', 'inspects processes', function(){
      return run(this.local, 'top -b -n 1 | head -n 12');
    }), task('df', 'inspects disk quotas', function(){
      return run(this.local, 'df');
    }), task('free', function(){
      return run(this.local, 'free');
    }), task('cmd', "Executes a command specified with -c `command`", function(){
      return run(this.local, this.args.command);
    }), task('sysg', "Copies syslog locally", function(){
      return get(this.local, '/var/log/syslog', './syslog');
    }), task('sysg-ls', "Copies syslog locally and launches log stash", function(){
      return get(this.local, '/var/log/syslog', '/tmp/syslog').then(function(){
        return runLsSyslog('/tmp/syslog');
      });
    }), task('npm', "Executes an npm command", function(){
      return run(this.local, "npm " + this.args.command);
    }), task('snpm', "Executes an npm command with sudo", function(){
      return run(this.local, "sudo npm " + this.args.command);
    }), task('dfj', 'inspects disk quotas', function(){
      return run(this.local, 'df-json', {
        silent: true
      }).then(function(it){
        return JSON.parse(it);
      }).then(function(it){
        var opts;
        opts = {
          sparkly: ['percent'],
          remove: ['filesystem']
        };
        return printAsTable(it, opts);
      });
    })), namespace('infoweb', 'tasks associated with the infoweb project', task('deploy', "Checks out repository in deployment space", function(){}), task('test', "Builds and tests project", function(){}))
  ]);
  module.exports.nodes = nodes;
  module.exports.namespace = ns;
}).call(this);
