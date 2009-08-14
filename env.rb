module Rakki
  include Ramaze::Optioned

  options.dsl do
    o "Title of site", :title,
      "Ramaze Wiki"

    o "Root directory", :root,
      File.dirname(__FILE__)

    o "Git repository location", :repo,
      File.expand_path(ENV['WIKI_HOME'] || File.join(self[:root], 'pages'))

    o "Default language", :default_language,
      'en'

    o "languages", :languages, [
      ['de', 'Deutsch'],
      ['en', 'English'],
      ['fr', 'Français'],
      ['ja', '日本語' ]
    ]
  end
end

Ramaze.options.merge!(
  'cache.names' => [:session, :feed, :git_blob, :git_log],
  'response.headers' => {
    'Accept-Charset' => 'utf-8',
    'Content-Type' => 'text/html; charset=utf-' })


DICTIONARY = Ramaze::Helper::Localize::Dictionary.new

Rakki.options.languages.each do |id, name|
  file = __DIR__("locale/locale_#{id}.yaml")

  begin
    DICTIONARY.load(id, :yaml => file)
  rescue Errno::ENOENT
    FileUtils.touch(file)
    retry
  end
end

module Org
  class Token
    include ToHtml
    include ToToc

    def html_a
      link, desc = *values

      if link =~ /:/
        leader, rest = link.split(/:/, 2)

        case leader
        when /^(https?|ftps?)$/
          link_external(link, desc || link)
        when /^swf$/
          link_swf(rest, desc)
        when /^irc$/
          link_irc(rest, desc)
        when /^wp$/
          link_wikipedia(rest, desc)
        when /^feed|rss|atom$/
          link_feed(rest, desc)
        else
          link_external(link, desc || link)
        end
      else
        lang = Innate::Current::session[:language] ||= 'en'
        link_internal(link, lang, desc || link)
      end
    end

    def link_internal(link, lang, desc)
      this = Innate::Current::action.params.join('/')
      exists = Rakki::Page[link.split('#').first, lang]
      style = "#{exists ? 'existing' : 'missing'}-wiki-link"
      tag(:a, desc, :href => Rakki::Pages.r(link), :class => style)
    end

    def link_external(link, desc)
      tag(:a, desc, :href => link, :class => 'wiki-link-external')
    end

    def link_irc(link, desc)
      tag(:a, desc, :href => "#{link}", :class => 'wiki-link-external')
    end

    def link_feed(link, desc)
      cache = Innate::Cache.feed

      if content = cache[link]
        content
      else
        content = build_feed(link, desc)
        cache.store(link, content, :ttl => 600)
      end

      return content
    rescue SocketError # so i can work on it local
      link = '/home/manveru/feeds/rss_v2_0_msgs.xml'
      retry
    end

    def build_feed(link, desc)
      feed = FeedConvert.parse(open(link))

      b = Builder::XmlMarkup.new

      b.div(:class => 'feed') do
        b.h2{ b.a(feed.title, :href => feed.link) } if desc

        b.ul do
          feed.items.map do |item|
            b.li do
              b.a(item.title, :href => item.link)
            end
          end
        end
      end

      b.target!
    end

    # TODO: format for search or name of article.
    #       "I'm feeling lucky" google search for wp might be best?
    def link_wikipedia(term, desc)
      # query = Rack::Utils.escape("site:wikipedia.org #{term}")
      # href = "http://google.com/?q=#{query}"
      term = Rack::Utils.escape(term)
      tag(:a, desc, :href => "http://en.wikipedia.org/w/#{term}", :class => 'wiki-link-external')
    end

    # what a fantastically cheap hack :)
    # use in your wiki like:
    # [[swf:some-vid][width: 600; height: 700; play: true]]
    SWF_DEFAULT = '; loop: false; quality: low; play: false'

    def link_swf(file, args)
      args << SWF_DEFAULT << "; movie: /swf/#{file}.swf"
      template = SWF_TEMPLATE.dup
      args.split(/\s*;\s*/).each do |subarg|
        key, value = subarg.split(/\s*:\s*/)
        template.gsub!("{#{key}}", value.dump)
      end

      return template
    end

    SWF_TEMPLATE = <<'SWF_TEMPLATE'
<object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" width={width} height={height} codebase="http://active.macromedia.com/flash5/cabs/swflash.cab#version=5,0,0,0">
  <param name=movie value={movie}>
  <param name=play value={play}>
  <param name=loop value={loop}>
  <param name=quality value={quality}>
  <embed src={movie} width={width} height={height} quality={quality} loop={loop} type="application/x-shockwave-flash" pluginspage="http://www.macromedia.com/shockwave/download/index.cgi?P1_Prod_Version=ShockwaveFlash">
  </embed>
</object>
SWF_TEMPLATE
  end
end
