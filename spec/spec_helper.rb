require 'bundler/setup'

require 'sdoc'

require 'minitest/autorun'

def with_env(env, &block)
  original_env = ENV.to_h
  ENV.replace(env)
  block.call
ensure
  ENV.replace(original_env)
end

def rdoc_run(*options)
  RDoc::RDoc.new.tap do |rdoc|
    rdoc.document(%W[--quiet --format=sdoc --template=rails] + options.flatten)
  end
end

def rdoc_dry_run(*options)
  rdoc_run("--dry-run", *options)
end

# Returns an RDoc::TopLevel instance for the given Ruby code.
def rdoc_top_level_for(ruby_code)
  # RDoc has a lot of internal state that needs to be initialized. The most
  # foolproof way to initialize it is by simply running it with a dummy file.
  $rdoc_for_specs ||= rdoc_dry_run("--files", __FILE__)

  $rdoc_for_specs.store = RDoc::Store.new

  Dir.mktmpdir do |dir|
    path = "#{dir}/ruby_code.rb"
    File.write(path, ruby_code)
    $rdoc_for_specs.parse_file(path)
  end
end
