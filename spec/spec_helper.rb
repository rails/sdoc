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

# Returns an RDoc::TopLevel instance for the given Ruby code.
def rdoc_top_level_for(ruby_code)
  # RDoc has a lot of internal state that needs to be initialized. The most
  # foolproof way to initialize it is by simply running it with a dummy file.
  $rdoc_for_specs ||= RDoc::RDoc.new.tap do |rdoc|
    rdoc.document(%W[--dry-run --quiet --format=sdoc --template=rails --files #{__FILE__}])
  end

  $rdoc_for_specs.store = RDoc::Store.new

  Dir.mktmpdir do |dir|
    path = "#{dir}/ruby_code.rb"
    File.write(path, ruby_code)
    $rdoc_for_specs.parse_file(path)
  end
end
