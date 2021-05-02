# Rack application for serving the documentation locally.
# After generating the documentation run:
#
#   bundle exec rackup config.ru
#
require 'bundler/setup'

root = "doc/public"
unless Dir.exists?(root)
  puts <<~MESSAGE
    Could not find any docs in #{root}.
    Run the following command to generate sample documentation:
      bundle exec rake test:rails
  MESSAGE
  exit
end

use Rack::Static,
  :urls => ["/files", "/images", "/js", "/css", "/panel", "/i", "/classes", "/ruby", "/rails"],
  :root => root
run lambda { |env|
  [
    200,
    {
      'Content-Type'  => 'text/html',
      'Cache-Control' => 'public, max-age=86400'
    },
    File.open("#{root}/index.html", File::RDONLY)
  ]
}
