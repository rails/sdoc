require 'sinatra'

set :public_folder, "doc/"
set :port, 8000

def h(html)
  Rack::Utils.escape_html(html)
end

def link(file, parent:)
  "<a href='/#{h(file.sub(settings.public_folder, ''))}'>#{h(file.sub(parent, ''))}</a>"
end

def li(file, parent: "")
  if Dir.exists?(file)
    file = "#{file}/"
    "<li>#{link(file, parent: parent)}#{ul(file)}</li>"
  else
    "<li>#{link(file, parent: parent)}</li>"
  end
end

def ul(dir)
  str = "<ul>"

  Dir[dir + "*"].sort.map do |file|
    str += li(file, parent: dir)
  end

  str + "</ul>"
end

get '/' do
  send_file File.join(settings.public_folder, 'index.html')
end

not_found do
  status 404
  ul(settings.public_folder)
end
