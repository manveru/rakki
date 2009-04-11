module Rakki
  class Auth < Controller
    map '/auth'

    def login
      redirect Pages.r('/') if logged_in?
      return unless request.post?

      redirect_referrer if user_login(request.params)
    end

    def logout
      user_logout
      redirect_referrer
    end
  end
end
