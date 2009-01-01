require 'git'

module Git
  module LibExtensions
    def log_commits_follow(opts = {})
      count, since, object, path_limiter, follow =
        opts.values_at(:count, :since, :object, :path_limiter)
      from, to = *opts[:between]

      arr = ['--pretty=oneline', '--follow']
      arr << "-#{count}" if count
      arr << "--since='#{since}'" if since
      arr << "#{from}..#{to}" if from and to
      arr << object if object
      arr << "-- #{path_limiter}" if path_limiter

      command_lines('log', arr, true).map { |l| l.split.first }
    end

    def commit(message, opts = {})
      arr_opts = ["-m '#{message}'"]
      arr_opts << '-a' if opts[:add_all]
      arr_opts += (opts[:files] || opts[:files]).map{|f| f.to_s.dump }
      command('commit', arr_opts)
    end
  end

  class Lib
    include LibExtensions
  end
end
