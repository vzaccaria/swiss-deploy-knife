(function(){
  var _, moment, fs, color, ref$, spawn, kill, __q, os, cl, ut, winston, dispOk, dispKo, disp, pdisp, pdeb, createPost, createContent, createLezione, createEsercitazione, _module, split$ = ''.split;
  _ = require('underscore');
  _.str = require('underscore.string');
  moment = require('moment');
  fs = require('fs');
  color = require('ansi-color').set;
  ref$ = require('child_process'), spawn = ref$.spawn, kill = ref$.kill;
  __q = require('q');
  os = require('os');
  cl = require('clark');
  ut = require('utf-8');
  winston = require('winston');
  dispOk = function(){
    return winston.info("Ok");
  };
  dispKo = function(it){
    return winston.error(it.toString());
  };
  disp = winston.info;
  pdisp = console.log;
  pdeb = winston.warn;
  _.mixin(_.str.exports());
  _.str.include('Underscore.string', 'string');
  createPost = function(name, content, category, date, tags){
    var tt, t, filename, text;
    tt = (function(){
      var i$, ref$, len$, results$ = [];
      for (i$ = 0, len$ = (ref$ = tags).length; i$ < len$; ++i$) {
        t = ref$[i$];
        results$.push("\"" + t + "\"");
      }
      return results$;
    }()).join(", ");
    filename = date.format("YYYY-MM-DD-") + _.slugify(name) + ".md";
    text = "---\ntitle: " + name + "\ndate: " + date.format('YYYY-MM-DD hh:mm:ss') + " \nlayout: post\ncategory : " + category + " \ntags : [ " + tt + " ] \n---\n\n" + content + " \n";
    return {
      filename: filename,
      text: text
    };
  };
  createContent = function(date, subCategory, tags){
    var taglist, t, text, nDate, r;
    taglist = (function(){
      var i$, ref$, len$, results$ = [];
      for (i$ = 0, len$ = (ref$ = tags).length; i$ < len$; ++i$) {
        t = ref$[i$];
        results$.push(t + "");
      }
      return results$;
    }()).join(", ");
    text = "\nEcco di seguito il materiale presentato nella " + subCategory + " in data " + date.format('D/M') + ":\n\n* " + taglist + "\n";
    nDate = subCategory + " del " + date.format('D/M') + (" su " + taglist);
    r = {
      name: nDate,
      content: text
    };
    return r;
  };
  createLezione = function(commaSeparatedTags){
    var tgs, ref$, name, content, po;
    tgs = split$.call(commaSeparatedTags, ',');
    ref$ = createContent(moment(), 'lezione', tgs), name = ref$.name, content = ref$.content;
    po = createPost(name, content, 'infob', moment(), tgs);
    return po;
  };
  createEsercitazione = function(commaSeparatedTags){
    var tgs, ref$, name, content, po;
    tgs = split$.call(commaSeparatedTags, ',');
    ref$ = createContent(moment(), 'esercitazione', tgs), name = ref$.name, content = ref$.content;
    po = createPost(name, content, 'infob', moment(), tgs);
    return po;
  };
  _module = function(){
    var innerModule, iface;
    this.shelljs = require('shelljs');
    innerModule = function(){
      return root;
    };
    iface = {
      innerModule: innerModule,
      createPost: createPost,
      createContent: createContent,
      createLezione: createLezione,
      createEsercitazione: createEsercitazione
    };
    return iface;
  };
  module.exports = _module();
}).call(this);
