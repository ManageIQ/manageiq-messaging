source 'https://rubygems.org'

# Specify your gem's dependencies in manageiq-messaging.gemspec
gemspec

minimum_version =
  case ENV['TEST_RAILS_VERSION']
  when "6.0"
    "~>6.0.4"
  when "7.0"
    "~>7.0.8"
  else
    "~>6.1.4"
  end

gem "activesupport", minimum_version
