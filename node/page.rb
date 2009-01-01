class PageNode
  include Innate::Node
  map '/'
  layout 'default'
  helper :user, :localize

  provide :html => :haml

  def index(*name)
    redirect r(:/, 'Home') if name.empty?
    @name = name.join('/')
    @page = page_of(@name)
    @title = to_title(@name)
    @toc, @html = @page.to_toc, @page.to_html
  end

  def edit(*name)
    redirect_referrer if name.empty? || !logged_in?
    @name = name.join('/')
    @page = page_of(@name)
    @title = to_title(@name)
    @text = @page.content
  end

  def save
    redirect_referrer unless logged_in?
    name, text = request[:name, :text]
    page = page_of(name)

    if text
      comment = page.exists? ? "Edit #{name}" : "Create #{name}"
      page.save(text, comment)
    end

    redirect r(:/, name)
  end

  def move
    redirect_referrer unless logged_in?
    from, to = request[:from, :to]

    if from and to
      page_of(name).move(to)
      redirect r(to)
    end

    redirect r(from)
  end

  def delete(name)
    redirect_referrer unless logged_in?
    raise "change"
    page_of(name).delete

    redirect r(:/)
  end

  def history(*name)
    @name = name.join('/')
    @page = page_of(name)
    @history = @page.history
  end

  def diff(sha, *file)
    @sha, @name = sha, file.join('/')
    style = session[:uv_style] = request[:uv_style] || session[:uv_style] || 'dawn'
    @styles = Uv.themes
    @text = Page.new(@name).diff(sha, style)
  end

  def show(sha, *file)
    @sha, @name = sha, file.join('/')
    @page = Page.new(@name, locale, sha)
    @title = to_title(@name)
    @toc, @html = @page.to_toc, @page.to_html
  end

  def list
    @list = nested_list(Page.list(locale))
  end

  def random
    pick = Page.list(locale).sort_by{ rand }.first
    redirect(r(:/, pick))
  end

  def language(name)
    session[:language] = name
    redirect_referrer
  end

  private

  def page_of(name)
    page = Page[name]
    page.language = locale
    page
  end

  def to_title(string)
    url_decode(string).gsub(/::/, ' ')
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
        ["<li>#{a(name, name)}</li>",
         "<ul>",
         final_nested_list(value, name),
         "</ul>"]
      end
    end
  end
end
