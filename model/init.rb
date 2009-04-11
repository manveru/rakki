require 'yaml/store'

module Rakki
  STORE = GitStore.new('pages')
  USERS = YAML::Store.new('accounts.yaml')

  require 'model/page'
  require 'model/user'
end
