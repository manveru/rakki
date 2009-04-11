require 'ramaze'
require 'ramaze/setup'

Ramaze.setup :verbose => true do
  gem 'ultraviolet', :lib => 'uv'
  gem 'git'
  gem 'org', :lib => 'org'
  gem 'builder'
end
