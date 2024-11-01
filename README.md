# SDoc

[![Tests](https://github.com/rails/sdoc/actions/workflows/test.yml/badge.svg)](https://github.com/rails/sdoc/actions/workflows/test.yml)

**Powering http://api.rubyonrails.org/**

### What is sdoc?

SDoc is an HTML template built on top of the RDoc documentation generator for Ruby code.

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

### Rake Task

If you want, you can setup a task in your `Rakefile` for generating your project's documentation via the `rake rdoc` command.

```ruby
# Rakefile
require 'sdoc' # and use your RDoc task the same way you used it before
require 'rdoc/task' # ensure this file is also required in order to use `RDoc::Task`

RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = 'doc/rdoc'      # name of output directory
  rdoc.options << '--format=sdoc' # explicitly set the sdoc generator
  rdoc.template = 'rails'         # template used on api.rubyonrails.org
end
```

NOTE: If you don't set `template` the default "sdoc" template is chosen, with a lighter color scheme.

Now you can execute this command with `rake rdoc`, to compile the documentation for the current project directory.

Alternatively you can pass this command a path to the project you wish to compile: `rake rdoc path/to/project`.

### RDoc

As mentioned before, SDoc is built on top of the RDoc project.

If you notice any bugs in the output of your documentation, it may be RDoc's fault and should be [reported upstream](https://github.com/ruby/rdoc/issues/new).

An example of an SDoc bug would be:

* Error or warning in JavaScript or HTML found in your browser
* Generation fails with some exception (likely due to incompatibility with RDoc)

Please feel free to still report issues here for both projects, especially if you aren't sure. We will try to redirect to the proper place if necessary.

## Contributing

If you'd like to contribute you can generate the Rails main branch documentation by running:

```bash
bundle exec rake test:rails
```

You can generate the Ruby default branch documentation by running:

```bash
bundle exec rake test:ruby
```

The generated documentation will be put into `doc/public` directory.
To view the just generated documentation start up a rack application by running:

```bash
bundle exec rackup config.ru
```

Then open http://localhost:9292 in the browser to view the documentation.

### Who?

* Vladimir Kolesnikov ([voloko](https://github.com/voloko))
* Nathan Broadbent ([ndbroadbent](https://github.com/ndbroadbent))
* Petrik de Heus ([p8](https://github.com/p8))
* ([zzak](https://github.com/zzak))
