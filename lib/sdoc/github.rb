module SDoc::GitHub
  def github_url(path)
    return false unless have_git?

    unless @github_url_cache.has_key? path
      @github_url_cache[path] = false
      file = @store.find_file_named(path)
      if file
        base_url = repository_url(path)
        if base_url
          relative_url = path_relative_to_repository(path)
          @github_url_cache[path] = "#{base_url}#{last_commit_sha1}#{relative_url}"
        end
      end
    end
    @github_url_cache[path]
  end

  protected

  def have_git?
    @have_git = system('git --version > /dev/null 2>&1') if @have_git.nil?
    @have_git
  end

  def last_commit_sha1
    return @sha1 if defined?(@sha1)

    @sha1 = Dir.chdir(base_dir) do
      `git rev-parse HEAD`.chomp
    end
  end

  def repository_url(path)
    return @repository_url if defined?(@repository_url)

    s = Dir.chdir(File.join(base_dir, File.dirname(path))) do
      `git config --get remote.origin.url`
    end

    m = s.match(%r{github.com[/:](.*)\.git$})
    @repository_url = m ? "https://github.com/#{m[1]}/blob/" : false
  end

  def path_relative_to_repository(path)
    absolute_path = File.join(base_dir, path)
    root = path_to_git_dir(File.dirname(absolute_path))
    absolute_path[root.size..absolute_path.size]
  end

  def path_to_git_dir(path)
    while !path.empty? && path != '.'
      if (File.exists? File.join(path, '.git'))
        return path
      end
      path = File.dirname(path)
    end
    ''
  end
end
