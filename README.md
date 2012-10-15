# SDoc

### What is it?

* shtml - RDoc's generator to build searchable documentation
* `sdoc-merge` - comand line tool to build merge multiple sdoc documentations
  packages into a single one
* `sdoc` - command line tool to run rdoc with generator=shtml

### Getting Started

```bash
  gem install sdoc
  sdoc -N projectdir
```

### Command line sdoc

sdoc is simply a wrapper to the rdoc command line tool. See `sdoc --help`
for more details. `--fmt` is set to shtml by default.
Default template `-T` is shtml. You can also use 'direct' template.

Example:

```bash
sdoc -o doc/rails -T direct rails
```

### Rake

```ruby
# Rakefile
require 'sdoc' # and use your RDoc task the same way you used it before

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'doc/rdoc'
  rdoc.options << '--fmt' << 'shtml' # explictly set shtml generator
  rdoc.template = 'direct' # lighter template used on railsapi.com
  ...
end
```

### sdoc-merge

<pre>
Usage: sdoc-merge [options] directories
    -n, --names [NAMES]              Names of merged repositories. Comma separated
    -o, --op [DIRECTORY]             Set the output directory
    -t, --title [TITLE]              Set the title of merged file
</pre>

Example:

```bash
sdoc-merge --title "Ruby v1.9, Rails v2.3.2.1" --op merged --names "Ruby,Rails" ruby-v1.9 rails-v2.3.2.1
```

# Who?

* Vladimir Kolesnikov ([voloko](https://github.com/voloko))
* Nathan Broadbent ([ndbroadbent](https://github.com/ndbroadbent))