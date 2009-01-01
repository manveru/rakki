module Innate
  module Helper
    module Localize
      def locale
        locale = session[:language] || Innate::Options.for(:wiki).default_language
        response['Content-Language'] = locale
      end

      def l(*strings)
        strings.map{|s| "((#{s}))" }.join(' ')
      end
    end
  end
end
