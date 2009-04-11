module Rakki
  class User
    def self.[](name)
      sync{|users| new(name, *users[name]) }
    rescue ArgumentError
    end

    def self.authenticate(hash)
      name, pass = hash.values_at('name', 'pass')
      return unless user = self[name]
      return unless user.digest == digestify(pass)
      user
    end

    def self.sync
      Ramaze.sync{ USERS.transaction{ yield(USERS) } }
    end

    def self.digestify(pass)
      Digest::SHA1.hexdigest(pass.to_s)
    end

    attr_accessor :name, :email, :digest

    def initialize(name, digest, email)
      @name, @digest, @email = name, digest, email
    end
  end
end
