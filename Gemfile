source "https://rubygems.org"

gemspec

gem "rake"
gem "minitest"
gem "hoe"

if RUBY_VERSION.to_f <= 2.5
  gem "psych", "< 4.0"
end

if ENV["rdoc"] == "master"
  gem "rdoc", :github => "ruby/rdoc"
end
