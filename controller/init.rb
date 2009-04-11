module Rakki
  class Controller < Ramaze::Controller
    layout :default
    map_layouts '/'
    helper :user, :localize, :flash

    trait :user_model => User

    private

    def localize_dictionary
      DICTIONARY
    end
  end
end

require 'controller/auth'
require 'controller/page'
