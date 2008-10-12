module Rack
  class Localize
    DEFAULT = {
      :mapping => { /^en-/ => 'en', 'ja' => 'jp' },
      :files => '/home/manveru/tmp/conf/locale_*.yaml',
      :regex => /\[\[([^\]]+)\]\]/,
      :default_language => 'en',
      :languages => %w[en],
      :persist => true,
    }

    # +:file+
    # +:default_language+
    # +:languages+
    # +:regex+
    # +:mapping+
    # +:persist+

    def initialize(options = {})
      @options = DEFAULT.merge(options)
    end

    def new(app)
      @app = app
      load_dictionaries
      return self
    end

    # Make sure to set the Content-Language header in your application
    # if you want to set a different default language.

    # Priority in choosing the language is as follows: First we will
    # serve the body in Content-Language if set and valid, then we try
    # to determine accepted languages of the client, if we can satisfy
    # the clients requirements we will serve it this way. Finally we
    # serve in the :default_language set in options if no other
    # options is available.

    # In your app you can access env['rack.localize.accept'] to
    # find out which languages the client would like to use.

    def call(env)
      accept_languages = env['HTTP_ACCEPT_LANGUAGE'].to_s.split(/(?:,|;q=[\d.,]+)/)
      env['rack.localize.accept'] = accept_languages

      status, headers, body = @app.call(env)

      content_language = headers['Content-Language']
      accept = [content_language, *accept_languages] << @options[:default_language]
      into = negotiate_locale(accept)

      accept.unshift(content_language) if content_language
      into = negotiate_locale(accept)

      localized_body = localize_body(body, into)
      headers.delete('Content-Length')

      Response.new(localized_body, status, headers).finish
    end

    def localize_body(body, into)
      body = unwrap_body(body)
      load_dictionaries

      body.gsub(@options[:regex]) do
        localize($1.strip, into) || $1
      end
    end

    def unwrap_body(body)
      out = ''; body.each{|b| out << b.to_s }; out
    end

    def localize(string, into)
      into.each do |lang|
        found = @dictionary[lang][string]
        return found
      end
    end

    def load_dictionaries
      @dictionary = {}

      files = Dir[@options[:files]]
      dictionary_ids = uncommon_substrings(*files)

      files.zip(dictionary_ids).each do |file, lang|
        @dictionary[lang] = load_dictionary(file)
      end
    end

    def add_missing_dictionaries(into)
      into.each do |lang|
        @dictionary[lang] ||= {}
      end
    end

    def negotiate_locale(accept)
      mapping = @options[:mapping]

      accept.select do |lang|
        mapped = mapping.find{|k,v| k === lang }
        lang = mapped[1] if mapped

        @dictionary.key?(lang)
      end
    end

    def load_dictionary(file)
      YAML.load_file(file)
    rescue Errno::ENOENT
      {}
    end

    def insert_missing(key, into)
      into[0..-2].each do |lang|
        @dictionary[lang][key] ||= @dictionary[into.last][key]
      end
    end

    # Find uncommon substrings from an array of strings.
    #
    # Usage:
    #   strings = %w[ locale_en.yaml locale_de.yaml locale_jp.yaml locale_pt-br.yaml ]
    #   uncommon_substrings(*strings)
    #   # => ["en", "de", "jp", "pt-br"]
    #
    # TODO: find out which algorithm to use for this, the current one is quite
    #       expensive.

    def uncommon_substrings(*strings)
      return if strings.empty?
      max = strings.map{|s| s.size }.max

      left = uncommon_substring_core(strings, max)
      right_needle = strings.map{|s| s[left..-1].reverse }
      right = uncommon_substring_core(right_needle, max)
      right_needle.map{|s| s[right..-1].reverse }
    end

    # Common algorithm to determine the left offset until strings become uncommon
    def uncommon_substring_core(needle, max)
      (0..max).find do |n|
        reg = /^#{'.' * n}(.*)/
          needle.map{|s| s[reg, 1][0,1] }.uniq.size > 1
      end
    end
  end
end

app = lambda{|env|
  r = Rack::Response.new
  r.write '[[hello]] manveru, [[how are you?]]'
  r.status = 200
  r.header['Content-Language'] = 'de' # uncomment that to enable real negotiation
  r.header['Content-Type'] = 'text/plain'
  r.finish
}

require 'rack'
Rack::Handler::Mongrel.run(Rack::Localize.new.new(app), :Port => 7000)
