module Innate
  module Helper
    module Localize
      def locale
        locale = session[:language] || RAKKI.default_language
        p :locale => locale
        response['Content-Language'] = locale
      end

      def l(*strings)
        strings.map{|s| "((#{s}))" }.join(' ')
      end
    end
  end
end
