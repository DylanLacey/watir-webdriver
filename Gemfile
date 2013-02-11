source "http://rubygems.org"

gem 'travis'
unless ENV['TRAVIS']
  gem "simplecov", ">= 0.3.5", :platform => :ruby_19
else
  gem "parallel_tests"
end

# Specify your gem's dependencies in watir-webdriver.gemspec
gemspec
