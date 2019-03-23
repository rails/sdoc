require 'sinatra'
require 'find'

set :public_folder, "doc"
set :port, 8000

def h(html)
  Rack::Utils.escape_html(html)
end

def relative(path)
  path.sub(settings.public_folder, '')
end

def li(path)
  "<li><a href=\"/#{h(relative(path))}\">#{h(relative(path))}</a></li>"
end

get '/' do
  send_file File.join(settings.public_folder, '/index.html')
end

not_found do
  status 404

  str = "<ul>"

  Find.find(settings.public_folder + '/') do |path|
    str += li(path)
  end

  str + "</ul>"
end
