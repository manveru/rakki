module Rakki
  class Pages < Controller
    map '/'

    def index(*name)
      redirect r(:/, 'Home') if name.empty?
      redirect r(:/, 'Home') unless @page = fetch_page(*name)

      @toc, @html = @page.to_toc, @page.to_html
    end

    def edit(*name)
      redirect_referrer if name.empty? || !logged_in?
      @page = fetch_page(*name)
      @text = @page.content
    end

    def save
      redirect_referrer unless request.post? && logged_in?
      name, text = request[:name, :text]

      if text and page = fetch_page(name)
        comment = page.exists? ? "Edit #{name}" : "Create #{name}"
        page.save(text, commit_author, comment)
      else
        flash[:error] = "No page for #{name}"
      end

      redirect r(:/, name)
    end

  def move(*name)
    redirect_referrer if name.empty? || !logged_in?

    setup_page(*name)

    return unless request.post?

    from, to = request[:from, :to]

    if from and to
      page_of(name).move(to)
      redirect r(to)
    end

    redirect r(from)
  end

  def delete(name)
    redirect_referrer unless logged_in?

    page_of(name).delete(commit_author)

    redirect r(:/)
  end

    def history(*name)
      redirect_referrer if name.empty?
      @page = fetch_page(*name)
      @history = @page.history
    end

    def diff(sha, *file)
      @sha, @name = sha, file.join('/')
      style = session[:uv_style] = request[:uv_style] || session[:uv_style] || 'dawn'
      @styles = Uv.themes
      @text = Page[@name, lang].diff(sha, style)
    end

    def show(sha, *file)
      @sha, @name = sha, file.join('/')
      @page = Page[@name, lang, sha]
      @title = @name
      @toc, @html = @page.to_toc, @page.to_html
    end

    def list
      @list = nested_list(Page.list(lang))
    end

    def random
      pick = Page.list(lang).sort_by{ rand }.first
      redirect(r(:/, pick))
    end

    def language(set)
      session[:lang] = set
      redirect_referrer
    end

    private

    def commit_author
      name, email = user.name, user.email
      "#{name} <#{email}>"
    end

    def fetch_page(*name)
      @name = name.join('/')
      @title = name.join(' ').gsub('::', ' ')
      Page[@name, lang] || Page[@name, Rakki.options.default_language]
    end

    def lang
      locale.language
    end

    # TODO: Make this more... elegant (maybe using Find.find as base),
    #       no time for that now
    def nested_list(list)
      final = {}

      list.each do |node|
        parts = node.split('/')
        parts.each_with_index do |part, idx|
          ref = final
          idx.times{|i| ref = ref[parts[i]] }
          ref[part] ||= {}
        end
      end

      final_nested_list(final).flatten.join("\n")
    end

    def final_nested_list(list, head = nil)
      list.map do |node, value|
        name = File.join(*[head, node].compact)
        if value.empty?
          "<li>#{a(name, name)}</li>"
        else
          [ "<li>#{a(name, name)}</li>",
            "<ul>",
            final_nested_list(value, name),
            "</ul>"]
        end
      end
    end
  end
end
