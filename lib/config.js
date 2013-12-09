(function(){
  var ref$, namespace, task, buildTasks, run, bsh, sequence, printAsTable, get, put, openTerminal, save, createLezione, createEsercitazione, saveRemotely, copy, nodes, x, s, f, localBinDir, b, ns;
  ref$ = require('swiss-deploy-knife/lib/task'), namespace = ref$.namespace, task = ref$.task, buildTasks = ref$.buildTasks, run = ref$.run, bsh = ref$.bsh, sequence = ref$.sequence;
  printAsTable = require('swiss-deploy-knife/lib/print').printAsTable;
  ref$ = require('swiss-deploy-knife/lib/ssh'), get = ref$.get, put = ref$.put, openTerminal = ref$.openTerminal, save = ref$.save;
  ref$ = require('swiss-deploy-knife/lib/jekyll'), createLezione = ref$.createLezione, createEsercitazione = ref$.createEsercitazione;
  saveRemotely = save;
  copy = function(x){
    var cmm;
    cmm = "echo '" + x + "' | pbcopy";
    console.log("Copying '" + x + "' to the clipboard");
    return shelljs.exec(cmm);
  };
  nodes = {
    w1: {
      description: "Website at www.vittoriozaccaria.net",
      path: {
        username: "vittoriozaccaria.net",
        hostname: "217.64.195.216",
        credentials: '/Users/zaccaria/.ssh/sftp_credentials.js',
        access: 'ftp'
      },
      saveTo: "data"
    },
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
    },
    s3: {
      description: "Macbook",
      path: {
        username: "zaccaria",
        hostname: "localhost",
        port: "22",
        credentials: '/Users/zaccaria/.ssh/id_rsa',
        hosttype: 'mac',
        access: 'ssh'
      }
    },
    'default': 's2'
  };
  x = function(c){
    return bsh("cd ~/test/infoweb/infoweb && sudo " + c);
  };
  s = function(c){
    return bsh("cd ~/test/infoweb/infoweb/node_modules/sails && sudo " + c);
  };
  f = function(c){
    return bsh("cd ~/test/infoweb/infoweb && sudo forever " + c);
  };
  localBinDir = 'bin';
  b = function(c){
    return "cd " + localBinDir + " && " + c;
  };
  ns = buildTasks([
    namespace('general', 'general commands applicable to almost all access modes', task('top', 'inspects processes', function(){
      return run(this.remote, 'top -b -n 1 | head -n 12');
    }), task('df', 'inspects disk quotas', function(){
      return run(this.remote, 'df');
    }), task('free', function(){
      return run(this.remote, 'free');
    }), task('cmd', "Executes a command specified with -c `command`", function(){
      return run(this.remote, this.args.command);
    }), task('sysg', "Copies syslog locally", function(){
      return get(this.remote, '/var/log/syslog', './syslog');
    }), task('npm', "Executes an npm command", function(){
      return run(this.remote, "npm " + this.args.command);
    }), task('snpm', "Executes an npm command with sudo", function(){
      return run(this.remote, "sudo npm " + this.args.command);
    }), task('dfj', 'inspects disk quotas', function(){
      var this$ = this;
      return run(this.remote, 'source .zshrc && df-json', {
        silent: true
      }).then(function(it){
        return JSON.parse(it);
      }).then(function(it){
        var opts;
        opts = {
          sparkly: ['percent', 'blocks'],
          remove: ['filesystem', 'used', 'available']
        };
        return printAsTable(this$.remote, it, opts);
      });
    }), task('ssh', 'launches an ssh term on the remote node', function(){
      return openTerminal(this.remote);
    }), task('vg1', 'inspects a running instance of vagrant', function(){
      return run(this.remote, ["bash -l -c 'cd /data2/zaccaria && vagrant status | grep default'"]);
    }), task('vg2', 'inspects a running instance of vagrant (local)', function(){
      return run(this.remote, ["bash -l -c 'cd ~/docker/docker && vagrant status | grep default'"]);
    }), task('seq', 'sequence test', function(){
      return sequence(this, ["df", "dfj"]);
    }), task('prepare-ngrok', 'Installs ngrok into target machine', function(){
      return run(this.remote, ["mkdir -p " + localBinDir, b("wget https://dl.ngrok.com/linux_386/ngrok.zip"), b("unzip ngrok.zip"), b("rm ngrok.zip")]);
    }), task('prepare-forever', 'Installs forever on target machine', function(){
      return run(this.remote, "sudo npm install -g n forever");
    }), task('qe', 'Expose a specific port on the web', function(){
      return run(this.remote, ["sudo forever start -c 'bash' " + localBinDir + "/ngrok.sh -proto=http -log='stdout' " + this.args.command, "sudo forever logs 0", "sudo forever logs 0", "sudo forever logs 0"]);
    }), task('eq', 'End exposure', function(){
      return run(this.remote, "sudo forever stop 0");
    }), task('fl', 'List forever processes', function(){
      return run(this.remote, f("list"));
    })), namespace('j', 'jekyll website tasks', task('lez', "Creates a post for a lezione, use -c 'tag1,tag2,...' for tags", function(){
      var post;
      post = createLezione(this.args.command);
      save(post, {
        to: "local:/Users/zaccaria/short/website/_posts/",
        'in': this.nodes
      });
      return copy("vi /Users/zaccaria/short/website/_posts/" + post.filename);
    }), task('ese', "Creates a post for an esercitazione, use -c 'tag1,tag2,...' for tags", function(){
      var post;
      post = createEsercitazione(this.args.command);
      save(post, {
        to: "local:/Users/zaccaria/short/website/_posts/",
        'in': this.nodes
      });
      return copy("vi /Users/zaccaria/short/website/_posts/" + post.filename);
    })), namespace('iwtest', 'tasks associated with testing the infoweb project', task('prepare', "Installs globally grunt, sails, n and node 0.10.13", function(){
      var this$ = this;
      return run(this.remote, "sudo npm install -g grunt-cli sails n mocha forever").then(function(){
        return run(this$.remote, "sudo n 0.10.13");
      });
    }), task('cleanup', "Cleans up remote test directories", function(){
      return run(this.remote, [bsh('sudo rm -rf ~/test/infoweb')]);
    }), task('preprov', "Creates the test directories", function(){
      return run(this.remote, [bsh('sudo mkdir -p ~/test'), bsh('sudo mkdir -p ~/test/infoweb')]);
    }), task('prov', "Checks out repository in ~/test/infoweb", function(){
      return run(this.remote, [bsh('cd ~/test/infoweb && sudo svn co -q https://zaccaria@svn.ws.dei.polimi.it/multicube/trunk/devel/zaccaria/infoweb')]);
    }), task('update', "Update repo in ~/test/infoweb", function(){
      return run(this.remote, [bsh('cd ~/test/infoweb && sudo svn update -q https://zaccaria@svn.ws.dei.polimi.it/multicube/trunk/devel/zaccaria/infoweb')]);
    }), task('install', "Executes `npm install` in ~/test/infoweb", function(){
      return run(this.remote, [x('npm install')]);
    }), task('build', "Executes `grunt deploy` in ~/test/infoweb", function(){
      return run(this.remote, x('grunt deploy'));
    }), task('setup-tests', "Installs dependencies associated with tests (e.g., shelljs)", function(){
      return run(this.remote, [x('npm install shelljs'), x('npm install ansi-color-table'), s('npm install')]);
    }), task('be2-test', function(){
      var this$ = this;
      return run(this.remote, x('./scripts/be2-test', {
        silent: true
      })).then(function(it){
        return save(it, {
          to: "w1:data/iwtest-be2.json",
          'in': this$.nodes
        });
      });
    }), task('be-test', function(){
      var this$ = this;
      return run(this.remote, x('./scripts/be-test', {
        silent: true
      })).then(function(it){
        return save(it, {
          to: "w1:data/iwtest-be.json",
          'in': this$.nodes
        });
      });
    }), task('fe-test', function(){
      var this$ = this;
      return run(this.remote, x('./scripts/fe-test', {
        silent: true
      })).then(function(it){
        return save(it, {
          to: "w1:data/iwtest-fe.json",
          'in': this$.nodes
        });
      });
    }), task('test', "Executes tests", function(){
      return sequence(this, ['be-test', 'be2-test', 'fe-test']);
    }), task('start', "Starts app in daemon mode", function(){
      return run(this.remote, f('start infoweb/app.js'));
    }), task('stop', "Stops app in daemon mode", function(){
      return run(this.remote, f('stop infoweb/app.js'));
    }), task('faststage', "Updates remote repo, runs `deploy` and `test`", function(){
      return sequence(this, ['update', 'build', 'test']);
    }))
  ]);
  module.exports.nodes = nodes;
  module.exports.namespace = ns;
}).call(this);
