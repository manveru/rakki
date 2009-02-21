require 'innate'
require 'innate/setup'
require 'uv'
require 'git'
require 'builder'

$LOAD_PATH.unshift File.dirname(__FILE__)

require 'org'
require 'vendor/rack/localize'
require 'vendor/feed_convert'

Uv.copy_files('xhtml', File.join(File.dirname(__FILE__), 'public'))

require 'env'
require 'model/page'
require 'node/page'
require 'node/auth'

Innate.start :adapter => :mongrel do |m|
  m.use(Rack::CommonLogger,
        Rack::ShowExceptions,
        Rack::ShowStatus,
        Rack::ConditionalGet,
        Rack::Head,
        Rack::Reloader,
        Rack::Localize.new(:languages => %w[en de jp], :files => 'locale/*.yaml'))
  m.innate
end
