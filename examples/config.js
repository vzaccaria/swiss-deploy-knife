// Generated by LiveScript 1.2.0
(function(){
  var ref$, namespace, task, buildTasks, run, runLocal, createLocal, removeLocal, zsh, bsh, sequence, printAsTable, get, put, openTerminal, save, mirror, createLezione, createEsercitazione, createComunicazione, saveRemotely, copy, mzsh, home, sshCred, nodes, localBinDir, ns;
  ref$ = require('swiss-deploy-knife/lib/task'), namespace = ref$.namespace, task = ref$.task, buildTasks = ref$.buildTasks, run = ref$.run, runLocal = ref$.runLocal, createLocal = ref$.createLocal, removeLocal = ref$.removeLocal, zsh = ref$.zsh, bsh = ref$.bsh, sequence = ref$.sequence;
  printAsTable = require('swiss-deploy-knife/lib/print').printAsTable;
  ref$ = require('swiss-deploy-knife/lib/ssh'), get = ref$.get, put = ref$.put, openTerminal = ref$.openTerminal, save = ref$.save, mirror = ref$.mirror;
  ref$ = require('swiss-deploy-knife/lib/jekyll'), createLezione = ref$.createLezione, createEsercitazione = ref$.createEsercitazione, createComunicazione = ref$.createComunicazione;
  saveRemotely = save;
  copy = function(x){
    var cmm;
    cmm = "echo '" + x + "' | pbcopy";
    console.log("Copying '" + x + "' to the clipboard");
    return shelljs.exec(cmm);
  };
  mzsh = function(c){
    return "zsh -l -c 'source .zshrc && " + c + "'";
  };
  home = process.env.HOME;
  sshCred = home + "/.ssh/id_rsa";
  nodes = {
    w1: {
      description: "Website at www.vittoriozaccaria.net",
      path: {
        username: "vittoriozaccaria.net",
        hostname: "217.64.195.216",
        credentials: home + "/.ssh/sftp_credentials.js",
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
        credentials: sshCred,
        hosttype: 'linux',
        access: 'ssh',
        shell: bsh,
        directory: '~'
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
        credentials: sshCred,
        hosttype: 'linux',
        access: 'ssh',
        login: {
          shell: bsh,
          runAsSudo: true,
          directory: '~/test/infoweb'
        }
      }
    },
    s3: {
      description: "Macbook",
      path: {
        username: "zaccaria",
        hostname: "localhost",
        port: "22",
        credentials: sshCred,
        hosttype: 'mac',
        access: 'ssh',
        login: {
          shell: mzsh,
          runAsSudo: false,
          directory: '~/test/infoweb'
        }
      }
    },
    s3root: {
      description: "Macbook",
      path: {
        username: "zaccaria",
        hostname: "localhost",
        port: "22",
        credentials: sshCred,
        hosttype: 'mac',
        access: 'ssh',
        login: {
          shell: mzsh,
          runAsSudo: false,
          directory: '~'
        }
      }
    },
    'default': 's3'
  };
  localBinDir = 'bin';
  if (require('os').hostname() === 'hbomb') {
    delete nodes['s2'].path.from;
    delete nodes['s2'].path.use;
  }
  ns = buildTasks([
    namespace('general', 'general commands applicable to almost all access modes', task('cmd', "Executes a command specified with -c `command`", function(){
      return run(this.remote, this.args.command);
    }), task('dfj', 'inspects disk quotas', function(){
      var this$ = this;
      return runLocal(this.remote, 'df-json', {
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
    })), namespace('mac', 'applicable to this mac', {
      defaultNode: 's3'
    }, task('vagrant-check', 'inspects a running instance of vagrant (local)', function(){
      return run(this.remote, ["bash -l -c 'cd ~/docker/docker && vagrant status | grep default'"]);
    })), namespace('hbomb', 'applicable to hbomb', {
      defaultNode: 's1'
    }, task('vagrant-check', 'inspects a running instance of vagrant', function(){
      return run(this.remote, ["bash -l -c 'cd /data2/zaccaria && vagrant status | grep default'"]);
    })), namespace('linux', 'general commands applicable to x86 hosts', {
      defaultNode: 's2'
    }, task('prepare-ngrok', 'Installs ngrok into target machine', function(){
      return runLocal(this.remote, ["mkdir -p " + localBinDir, "rm ngrok.zip", "rm ngrok", "wget https://dl.ngrok.com/linux_386/ngrok.zip", "wget http://www.vittoriozaccaria.net/deposit/ngrok.sh", "unzip ngrok.zip", "rm ngrok.zip", "mv ngrok " + localBinDir, "mv ngrok.sh " + localBinDir]);
    }), task('prepare-forever', 'Installs forever on target machine', function(){
      return runLocal(this.remote, "npm install -g n forever");
    })), namespace('jekyll', 'jekyll website tasks', {
      defaultNode: 's3'
    }, task('lezione', "Creates a post for a lezione, use -c 'tag1,tag2,...' for tags", function(){
      var post;
      post = createLezione(this.args.tags);
      save(post, {
        to: "local:/Users/zaccaria/short/website/_posts/",
        'in': this.nodes
      });
      return copy("vi /Users/zaccaria/short/website/_posts/" + post.filename);
    }), task('esercitazione', "Creates a post for an esercitazione, use -c 'tag1,tag2,...' for tags", function(){
      var post;
      post = createEsercitazione(this.args.tags);
      save(post, {
        to: "local:/Users/zaccaria/short/website/_posts/",
        'in': this.nodes
      });
      return copy("vi /Users/zaccaria/short/website/_posts/" + post.filename);
    }), task('comunicazione', "Creates a post for a comunicazione, use -c 'tag1,tag2,...' for tags", function(){
      var post;
      post = createComunicazione(this.args.tags);
      save(post, {
        to: "local:/Users/zaccaria/short/website/_posts/",
        'in': this.nodes
      });
      return copy("vi /Users/zaccaria/short/website/_posts/" + post.filename);
    }), task('deploy', "Deploy the website", function(){
      var this$ = this;
      return runLocal(this.remote, "cd /Users/zaccaria/short/website && make", {
        silent: true
      }).then(function(){
        return mirror({
          from: "local:/Users/zaccaria/short/website/_site",
          to: "w1:.",
          'in': this$.nodes
        });
      });
    })), namespace('infoweb', 'tasks associated with testing the infoweb project', {
      defaultNode: 's2'
    }, task('buildenv-create', "Creates the environment for infoweb, using default-node data", function(){
      return createLocal(this.remote);
    }), task('buildenv-remove', "Removes the environment for infoweb, using default node data", function(){
      return removeLocal(this.remote);
    }), task('buildenv-prepare', "Installs globally grunt, sails, n and node 0.10.13", function(){
      var this$ = this;
      return runLocal(this.remote, "npm install -g grunt-cli sails n mocha forever", {
        runAsSudo: true
      }).then(function(){
        return runLocal(this$.remote, "n 0.10.13");
      });
    }), task('src-checkout', "Checks out repository in ~/test/infoweb", function(){
      return runLocal(this.remote, 'svn co -q https://zaccaria@svn.ws.dei.polimi.it/multicube/trunk/devel/zaccaria/infoweb');
    }), task('src-update', "Update repo in ~/test/infoweb", function(){
      return runLocal(this.remote, 'svn update infoweb');
    }), task('src-link-packages', "Executes `npm install` in ~/test/infoweb", function(){
      var this$ = this;
      return runLocal(this.remote, 'npm install', {
        subDir: 'infoweb'
      }).then(function(){
        return runLocal(this$.remote, 'npm install shelljs ansi-color-table', {
          subDir: 'infoweb'
        });
      }).then(function(){
        return runLocal(this$.remote, 'npm install', {
          subDir: 'infoweb/node_modules/sails'
        });
      });
    }), task('src-compile', "Executes `grunt deploy` in ~/test/infoweb", function(){
      return runLocal(this.remote, 'grunt deploy', {
        subDir: 'infoweb'
      });
    }), task('test-be2', function(){
      var this$ = this;
      return runLocal(this.remote, './scripts/be2-test', {
        subDir: 'infoweb',
        silent: true
      }).then(function(it){
        return save(it, {
          to: "w1:data/iwtest-be2.json",
          'in': this$.nodes
        });
      });
    }), task('test-be', function(){
      var this$ = this;
      return runLocal(this.remote, './scripts/be-test', {
        subDir: 'infoweb',
        silent: true
      }).then(function(it){
        return append(it, {
          to: "w1:data/iwtest-be.json",
          'in': this$.nodes
        });
      });
    }), task('test-fe', function(){
      var this$ = this;
      return runLocal(this.remote, './scripts/fe-test', {
        subDir: 'infoweb',
        silent: true
      }).then(function(it){
        return save(it, {
          to: "w1:data/iwtest-fe.json",
          'in': this$.nodes
        });
      });
    }), task('test-all', "Executes tests", function(){
      return sequence(this, ['test-be', 'test-be2', 'test-fe']);
    }), task('test-fast-stage', "Updates and compiles", function(){
      return sequence(this, ['src-update', 'src-link-packages', 'src-compile']);
    }), task('test-after-fast-staging', "Updates remote repo, runs `deploy` and `test`", function(){
      return sequence(this, ['test-fast-stage', 'test-all']);
    }), task('test-complete-stage', "Checks out and compiles", function(){
      return ['buildenv-remove', 'buildenv-create', 'src-checkout', 'src-link-packages', 'src-compile'];
    }), task('test-after-complete-staging', "Cleans up everything and reinstall to test", function(){
      return sequence(this, ['test-fast-stage', 'test-all']);
    }), task('test-e2e-start', "Starts app in test mode", function(){
      return runLocal(this.remote, 'NODE_TEST=true forever start app.js', {
        subDir: 'infoweb/infoweb'
      });
    }), task('test-e2e-stop', "Stops app in test mode", function(){
      return runLocal(this.remote, 'NODE_TEST=true forever stop app.js', {
        subDir: 'infoweb/infoweb'
      });
    }), task('test-e2e-engage', "End to end test", function(){
      var this$ = this;
      return runLocal(this.remote, './scripts/e2e-test', {
        subDir: 'infoweb',
        silent: true
      }).then(function(it){
        return save(it, {
          to: "w1:data/iwtest-e2e.json",
          'in': this$.nodes
        });
      }).then(function(){
        return runLocal(this$.remote, 'killall phantomjs');
      });
    }), task('test-e2e', "Starts test server, tests e2e and shutsdown test server", function(){
      return sequence(this, ['test-e2e-start', 'test-e2e-engage', 'test-e2e-stop']);
    }), task('prod-start', "Starts app in production mode", function(){
      return runLocal(this.remote, 'NODE_ENV=production forever start app.js', {
        subDir: 'infoweb/infoweb'
      });
    }), task('prod-stop', "Stops app in production  mode", function(){
      return runLocal(this.remote, 'NODE_ENV=production forever stop app.js', {
        subDir: 'infoweb/infoweb'
      });
    }), task('prod-openport', "Opens 80 through ngrok", function(){
      var auth;
      auth = require('/Users/zaccaria/.ssh/ngrok_credentials.js').token;
      return runLocal(this.remote, ["forever start -c 'bash' " + localBinDir + "/ngrok.sh -authtoken " + auth + " -subdomain=vz-infoweb-prod  -proto=http -log='stdout' 80 "]);
    }), task('prod-lift', "Lift app and start ngrok", function(){
      return sequence(this, ['prod-start', 'prod-openport']);
    }), task('forever-stopall', "Close app", function(){
      return runLocal(this.remote, "forever stopall");
    }), task('forever-list', 'List forever processes', function(){
      return runLocal(this.remote, "forever list");
    }), task('ssh', 'Launches an ssh term on the remote node', function(){
      return openTerminal(this.remote);
    }))
  ]);
  module.exports.nodes = nodes;
  module.exports.namespace = ns;
}).call(this);
