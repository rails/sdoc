module SDoc::Helpers::Git
  def _git
    @@_git ||= {}
  end

  def github_url(relative_path, line: nil)
    return unless github?
    line = "#L#{line}" if line
    "https://github.com/#{github_repository}/blob/#{git_head_sha1}/#{relative_path}#{line}"
  end

  def github?
    @options.github && git? && github_repository
  end

  def git?
    _git[:repo_path] ||= Dir.chdir(@options.root) { `git rev-parse --show-toplevel 2> /dev/null`.chomp }
    !_git[:repo_path].empty?
  end

  def git_command(command)
    Dir.chdir(@options.root) { `git #{command}`.chomp } if git?
  end

  def git_head_branch
    _git[:head_branch] ||= git_command("rev-parse --abbrev-ref HEAD")
  end

  def git_head_sha1
    _git[:head_sha1] ||= git_command("rev-parse HEAD")
  end

  def git_head_timestamp
    _git[:head_timestamp] ||= git_command("show -s --format=%cI HEAD")
  end

  def git_origin_url
    _git[:origin_url] ||= git_command("config --get remote.origin.url")
  end

  def github_repository
    _git.fetch(:github_repository) do
      _git[:github_repository] = git_origin_url.chomp(".git")[%r"github\.com[/:](.+)", 1]
    end
  end
end
