require 'logger'
require 'vendor/git_extension'

module Rakki
  class Page
    EXT = '.org'

    def self.blob_cache
      Ramaze::Cache.git_blob
    end

    def self.log_cache
      Ramaze::Cache.git_log
    end

    def self.repo(*args)
      File.join(Rakki.options.repo, *args)
    end

    def self.list(language)
      files = []
      prefix = /^#{Regexp.escape(language)}\/*/
      suffix = /#{Regexp.escape(EXT)}$/

      G.ls_files_in language do |file|
        files << file.sub(prefix, '').sub(suffix, '')
      end

      files
    end

    def self.list_render
      out = ["* List"] + list.map{|path| " * [[#{path}]]" }
      render(out * "\n")
    end

    def self.diff(sha, style)
      uv_diff(G.diff(sha).patch, style)
    end

    def self.uv_diff(string, style)
      Uv.parse(string, 'xhtml', 'diff', false, style, false)
    end

    def self.show(sha, file)
      G.gblob("#{sha}:#{file}").contents
    end

    def self.init(repo = self.repo, language = Rakki.options.default_language)
      lang_home = File.join(default_language, "Home#{EXT}")
      FileUtils.mkdir_p(repo(language))

      Dir.chdir(repo){
        FileUtils.touch(lang_home)
        Git.init('.')
      }

      g = Git.open(repo)
      g.add(lang_home)
      g.better_commit(
        'Inaugural commit',
        :files => [lang_home],
        :author => 'Rakki Wiki <rakki@localhost>'
      )
    end

    def self.[](name, language, revision = nil)
      if revision
        new(File.join(language, "#{name}#{EXT}"), revision)
      else
        new(File.join(language, "#{name}#{EXT}"))
      end
    end

    begin
      G = Git.open(repo) # , :log => Ramaze::Log)
    rescue ArgumentError => ex
      init
      retry
    end

    include Ramaze::Helper::Localize

    attr_reader :path

    def initialize(path, revision = self.revision)
      @path, @revision = path, revision
      @org = nil
    end

    def diff(sha, style)
      diff = G.gcommit(sha).diff(path).patch
      self.class.uv_diff(diff, style)
    end

    def read(rev = revision)
      return nil unless rev
      ref = "#{rev}:#{path}"
      self.class.blob_cache[ref] ||= G.gblob(ref).contents + "\n"
    rescue Git::GitExecuteError => ex
      Ramaze::Log.error(ex)
      nil
    rescue Errno::ENOENT
      nil
    end

    def revision
      @revision ||= revisions.first
    end

    def revisions
      object = "-- #{path}"
      self.class.log_cache[object] = G.lib.log_commits(:object => object)
    rescue Git::GitExecuteError => ex
      Ramaze::Log.error(ex)
      []
    end

    # TODO: make sure this is threadsafe
    def save(content, author, comment = "Update #@name")
      file = self.class.repo(path)
      FileUtils.mkdir_p(File.dirname(file))
      File.open(file, 'w+'){|i| i.puts content.gsub(/\r\n|\r/, "\n") }
      G.add(path) unless revision
      message = G.better_commit(comment, :files => [path], :author => author)
      @revision = message[/Created commit (\w+):/, 1]
    rescue Git::GitExecuteError => ex
      Ramaze::Log.error(ex)
      nil
    end

    # TODO: make sure this is threadsafe
    def move(to, comment = "Move #@name to #{to}")
      return unless exists?
      return if @name == to
#       G.lib.mv(path, repo_file(to))
      message = G.better_commit(comment)
      @revision = message[/Created commit (\w+):/, 1]
      @name = to
    rescue Git::GitExecuteError => ex
      Ramaze::Log.error(ex)
      nil
    end

    def delete(author, comment = "Delete #@name")
      return unless exists?
      G.lib.remove(path)
      message = G.better_commit(comment, :author => author)
    rescue Git::GitExecuteError => ex
      Ramaze::Log.error(ex)
      nil
    end

    def history
      G.lib.log_commits_follow(:object => path).map do |rev|
        G.gcommit(rev)
      end
    end

    def render(string = content)
      self.class.render(string)
    end

    def to_html
      org.to_html
    end

    def to_toc
      org.to_toc
    end

    def org
      @org ||= Org::OrgMode.apply(content)
    end

    def content
      read || ''
    end

    def exists?(rev = self.revision)
      G.object_exists?("#{rev}:#{path}")
    end
  end
end
