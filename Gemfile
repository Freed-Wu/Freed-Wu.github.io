# frozen_string_literal: true

source 'https://rubygems.org'

require 'yaml'
config = YAML.load_file('_config.yml')
config['plugins'].each do |plugin|
  gem plugin
end
gem 'netrc'

# Performance-booster for watching directories on Windows
platforms :mingw, :x64_mingw, :mswin do
  gem 'wdm', '~> 0.1.1'
end
