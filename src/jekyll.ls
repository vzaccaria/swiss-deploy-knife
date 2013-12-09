_               = require('underscore')
_.str           = require('underscore.string');
moment          = require 'moment'
fs              = require 'fs'
color           = require('ansi-color').set
{ spawn, kill } = require('child_process')
__q             = require('q')

os              = require('os')
cl              = require('clark')
ut              = require('utf-8')
winston         = require('winston')

disp-ok = -> 
  winston.info "Ok"
  
disp-ko = -> 
  winston.error it.toString()
  
disp    = winston.info
pdisp   = console.log
pdeb    = winston.warn

_.mixin(_.str.exports());
_.str.include('Underscore.string', 'string');

# usage rake new_post[my-new-post] or rake new_post['my new post'] or rake new_post (defaults to "new-post")
#desc "Begin a new post in #{source_dir}/#{posts_dir}"
#task :new_post, :title do |t, args|
##  raise "### You haven't set anything up yet. First run `rake install` to set up an Octopress theme." unless File.directory?(source_dir)
#  mkdir_p "#{source_dir}/#{posts_dir}"
#  args.with_defaults(:title => 'new-post')
#  title = args.title
#  filename = "#{source_dir}/#{posts_dir}/#{Time.now.strftime('%Y-%m-%d')}-#{title.to_url}.#{new_post_ext}"
#  if File.exist?(filename)
#    abort("rake aborted!") if ask("#{filename} already exists. Do you want to overwrite?", ['y', 'n']) == 'n'
#  end
#  puts "Creating new post: #{filename}"
#  open(filename, 'w') do |post|
#    post.puts "---"
#    post.puts "layout: post"
#    post.puts "title: \"#{title.gsub(/&/,'&amp;')}\""
#    post.puts "date: #{Time.now.strftime('%Y-%m-%d %H:%M')}"
#    post.puts "comments: true"
#    post.puts "category: blog"
#    post.puts "---"
#  end
#  system("vi #{filename}")
#end
# date: 2013-12-09 10:42:46

create-post = (name, content, category, date, tags) ->
  tt = [ "\"#t\"" for t in tags ] * ", "
  filename = date.format("YYYY-MM-DD-") + _.slugify(name) + ".md"
  text = 
    """
    ---
    title: #{name}
    date: #{date.format('YYYY-MM-DD hh:mm:ss')} 
    layout: post
    category : #{category} 
    tags : [ #tt ] 
    ---

    #content 

    """
  return { filename: filename, text: text }
  # return filename

create-content = (date, sub-category, tags) ->

  taglist = [ "#t" for t in tags ] * ", "

  text = 

    """

    Ecco di seguito il materiale presentato nella #{sub-category} in data #{date.format 'D/M'}:

    * #{taglist}

    """
  n-date = sub-category + " del " + date.format('D/M') + " su #{taglist}"
  r = { name: n-date, content: text}
  return r





create-lezione = (comma-separated-tags) ->
  tgs = comma-separated-tags / ','
  {name, content} = create-content(moment(), 'lezione', tgs)
  po = create-post(name, content, 'infob', moment(), tgs)
  return po


create-esercitazione = (comma-separated-tags) ->
  tgs = comma-separated-tags / ','
  {name, content} = create-content(moment(), 'esercitazione', tgs)
  po = create-post(name, content, 'infob', moment(), tgs)

  return po

_module = ->

    @shelljs = require('shelljs')

    inner-module = ->
      # Use `inner-module` to inject dependencies into `dep`
      # e.g. sinon.stub mod.inner-module().dep, 'method'.
      #
      # You can access `dep` method with plain `dep.method`
      # in functions defined below.
      return root
          
    iface = { 
      inner-module: inner-module
      create-post: create-post
      create-content: create-content
      create-lezione: create-lezione
      create-esercitazione: create-esercitazione
    }
  
    return iface
 
module.exports = _module()




# _module().create-post "questa è una prova", \infob, moment(), ["esercitazione", "lezione"]
# _module().create-content moment(), 'lezione', [ 'matlab', 'matrici', 'funzioni' ]





