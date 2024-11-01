# Rack application for serving the documentation locally.
# After generating the documentation run:
#
#   bundle exec rackup config.ru
#
require 'bundler/setup'

root = "doc/public"
unless Dir.exist?(root)
  puts <<~MESSAGE
    Could not find any docs in #{root}.
    Run the following command to generate sample documentation:
      bundle exec rake test:rails
  MESSAGE
  exit
end

require "rack/static"
use Rack::Static,
  :urls => ["/files", "/images", "/js", "/css", "/panel", "/i", "/fonts", "/classes", "/ruby", "/rails"],
  :root => root
run lambda { |env|
  [
    200,
    {
      'content-type'  => 'text/html',
      'cache-control' => 'public, max-age=86400'
    },
    File.open("#{root}/index.html", File::RDONLY)
  ]
}
