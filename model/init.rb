require 'yaml/store'

module Rakki
  USERS = YAML::Store.new('accounts.yaml')

  require 'model/page'
  require 'model/user'
end
