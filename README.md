# SDoc

[![Build Status](https://travis-ci.org/zzak/sdoc.png?branch=master)](https://travis-ci.org/zzak/sdoc)

**Powering http://api.rubyonrails.org/**

### What is sdoc?

SDoc is an HTML template built on top of the RDoc documentation generator for Ruby code.

Provided are two command-line tools you get when you installing the gem:

* `sdoc` - command line tool to run rdoc with `generator=shtml` (searchable HTML)
* `sdoc-merge` - command line tool to merge multiple sdoc folders into a single documentation site

### Getting Started

```bash
# Install the gem
gem install sdoc

# Generate documentation for 'projectdir'
sdoc projectdir
```

### sdoc

`sdoc` is simply a wrapper for the `rdoc` command line tool. See `sdoc --help` for more details.

When using the `sdoc` command, `--fmt` is set to `shtml` by default. The default template (or `-T` option) is set to `shtml`, but you can also use the `direct` template when generating documentation.

Example:

```bash
sdoc -o doc/rails -T direct rails
```

### sdoc-merge

`sdoc-merge` is useful tool for combining multiple projects documentation into one HTML website. See `sdoc-merge --help` for more details.

```
Usage: sdoc-merge [options] directories
    -n, --names [NAMES]              Names of merged repositories. Comma separated
    -o, --op [DIRECTORY]             Set the output directory
    -t, --title [TITLE]              Set the title of merged file
```

Example:

```bash
sdoc-merge --title "Ruby v1.9, Rails v2.3.2.1" --op merged --names "Ruby,Rails" ruby-v1.9 rails-v2.3.2.1
```

### Rake Task

If you want, you can setup a task in your `Rakefile` for generating your project's documentation via the `rake rdoc` command.

```ruby
# Rakefile
require 'sdoc' # and use your RDoc task the same way you used it before
require 'rdoc/task' # ensure this file is also required in order to use `RDoc::Task`

RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = 'doc/rdoc' # name of output directory
  rdoc.generator = 'sdoc' # explictly set the sdoc generator
  rdoc.template = 'rails' # template used on api.rubyonrails.org
end
```

NOTE: If you don't set `template` the default "sdoc" template is chosen, with a lighter color scheme.

Now you can execute this command with `rake rdoc`, to compile the documentation for the current project directory.

Alternatively you can pass this command a path to the project you wish to compile: `rake rdoc path/to/project`.

### RDoc

As mentioned before, SDoc is built on top of the RDoc project.

If you notice any bugs in the output of your documentation, it may be RDoc's fault and should be [reported upstream](https://github.com/rdoc/rdoc/issues/new).

An example of an SDoc bug would be:

* Exception is raised when merging project documentation (ala `sdoc-merge`)
* Error or warning in JavaScript or HTML found in your browser
* Generation fails with some exception (likely due to incompatibility with RDoc)

Please feel free to still report issues here for both projects, especially if you aren't sure.

As maintainer of both projects, I'll see if I can identify the root of the cause :bow: :bow: :bow:


### Who?

* Vladimir Kolesnikov ([voloko](https://github.com/voloko))
* Nathan Broadbent ([ndbroadbent](https://github.com/ndbroadbent))
* Zachary Scott ([zzak](https://github.com/zzak))
