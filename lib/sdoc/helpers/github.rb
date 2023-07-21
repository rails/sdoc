module SDoc::Helpers::GitHub
  def github_url(relative_path, line: nil)
    return unless github?
    line = "#L#{line}" if line
    "https://github.com/#{github_repository}/blob/#{git_head_sha1}/#{relative_path}#{line}"
  end

  def github?
    @options.github && git? && github_repository
  end

  attr_writer :git_bin_path

  def git?
    @git_bin_path ||= `sh -c 'command -v git'`.chomp
    !@git_bin_path.empty?
  end

  attr_writer :git_head_sha1

  def git_head_sha1
    @git_head_sha1 ||= Dir.chdir(@options.root) do
      `git rev-parse HEAD`.chomp
    end
  end

  attr_writer :git_origin_url

  def git_origin_url
    @git_origin_url ||= Dir.chdir(@options.root) do
      `git config --get remote.origin.url`.chomp
    end
  end

  def github_repository
    return @github_repository if defined?(@github_repository)
    @github_repository = git_origin_url.chomp(".git")[%r"github\.com[/:](.+)", 1]
  end
end
