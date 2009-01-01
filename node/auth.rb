require 'yaml/store'

class User
  ACCOUNTS = YAML::Store.new('accounts.yaml')

  def self.register(name, pass)
    sync do |acc|
      acc[name] = digestify(pass)
    end
  end

  def self.check(name, pass)
    sync do |acc|
      return acc[name] == digestify(pass)
    end
  end

  def self.sync
    Innate.sync{ ACCOUNTS.transaction{ yield(ACCOUNTS) } }
  end

  def self.digestify(pass)
    Digest::SHA1.hexdigest(pass)
  end
end

class Auth
  include Innate::Node
  map '/auth'
  layout :default
  provide :html => :haml
  helper :user, :localize

  def login
    redirect PageNode.r('/') if logged_in?
    return unless request.post?

    user, pass = request[:user, :pass]

    if ::User.check(user.to_s.strip, pass.to_s.strip)
      session[:user] = user
      redirect_referrer
    end
  end

  def logout
    session.delete(:user)
    redirect_referrer
  end
end
