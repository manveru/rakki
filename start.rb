dir = File.expand_path(File.dirname(__FILE__))

$LOAD_PATH.unshift(dir)
Dir["#{dir}/vendor/*/lib"].each{|lib| $LOAD_PATH.unshift(lib) }

require 'ramaze'
require 'vendor/feed_convert'

Ramaze.setup do
  gem 'org'
  gem 'ultraviolet', :lib => 'uv'
  gem 'builder'
end

Uv.copy_files('xhtml', File.join(File.dirname(__FILE__), 'public'))

require 'yaml/store'
require 'ramaze/helper/localize'
require 'ramaze/helper/user'

require 'env'
require 'model/init'
require 'controller/init'

Ramaze.start :adapter => :mongrel, :mode => :live
