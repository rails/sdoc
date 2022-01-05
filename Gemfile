source "https://rubygems.org"

gemspec

gem "rack"
gem "rake"
gem "hoe"
gem "minitest"


if RUBY_VERSION.to_f <= 2.5
  gem "psych", "< 4.0"
end

if ENV["rdoc"] == "master"
  gem "rdoc", :github => "ruby/rdoc"
end
