require 'optparse'
require 'pathname'
require 'fileutils'
require 'json'

class SDoc::Merge
  
  FLAG_FILE = "created.rid"
  
  def initialize()
    @names = []
    @op_dir = 'doc'
    @directories = []
  end
  
  def merge(options)
    parse_options options
    
    check_directories
    setup_output_dir
    setup_names
    copy_files
    merge_tree
    merge_search_index
  end
  
  def parse_options(options)
    opts = OptionParser.new do |opt|     
      opt.banner = "Usage: sdoc-merge [options] directories"
      
      opt.on("-n", "--names [NAMES]", "Names of merged repositories. Comma separated") do |v|
        @names = v.split(',').map{|name| name.strip }
      end
      
      opt.on("-o", "--op [DIRECTORY]", "Set the output directory") do |v|
        @op_dir = v
      end
    end
    opts.parse! options
    @directories = options.dup
  end
  
  def merge_tree
    tree = []
    @directories.each_with_index do |dir, i|
      name = @names[i]
      filename = File.join dir, RDoc::Generator::SHtml::TREE_FILE
      data = open(filename).read.sub(/var tree =\s*/, '')
      subtree = JSON.parse data
      item = [
        name,
        '',
        '',
        append_path(subtree, name)
      ]
      tree << item
    end
    
    dst = File.join @op_dir, RDoc::Generator::SHtml::TREE_FILE
    FileUtils.mkdir_p File.dirname(dst)
    File.open(dst, "w") do |f|
      f.write('var tree = '); f.write(tree.to_json)
    end
  end
  
  def append_path subtree, path
    subtree.map do |item|
      item[1] = path + '/' + item[1] unless item[1].empty?
      item[3] = append_path item[3], path
      item
    end
  end
  
  def merge_search_index
    items = []
    @directories.each_with_index do |dir, i|
      name = @names[i]
      filename = File.join dir, RDoc::Generator::SHtml::SEARCH_INDEX_FILE
      data = open(filename).read.sub(/var search_data =\s*/, '')
      subindex = JSON.parse data
      
      searchIndex = subindex["index"]["searchIndex"]
      longSearchIndex = subindex["index"]["longSearchIndex"]
      subindex["index"]["info"].each_with_index do |info, j|
        info[2] = name + '/' + info[2]
        info[6] = i
        items << {
          :info => info,
          :searchIndex => searchIndex[j],
          :longSearchIndex => name + ' ' + longSearchIndex[j]
        }
      end
    end
    items.sort! do |a, b|
      a[:info][5] == b[:info][5] ?        # type (class/method/file)
        (a[:info][0] == b[:info][0] ?     # or name
          (a[:info][6] == b[:info][6] ?   # or doc part
            a[:info][1] <=> b[:info][1] :  # or namespace
            a[:info][6] <=> b[:info][6]
          ) :
          a[:info][0] <=> b[:info][0]
        ) : 
        a[:info][5] <=> b[:info][5]
    end
    
    index = {
      :searchIndex => items.map{|item| item[:searchIndex]},
      :longSearchIndex => items.map{|item| item[:longSearchIndex]},
      :info => items.map{|item| item[:info]}
    }
    search_data = {
      :index => index,
      :badges => @names
    }
    
    dst = File.join @op_dir, RDoc::Generator::SHtml::SEARCH_INDEX_FILE
    FileUtils.mkdir_p File.dirname(dst)
    File.open(dst, "w") do |f|
      f.write('var search_data = '); f.write(search_data.to_json)
    end
  end
  
  def setup_names
    unless @names.size
      @directories.each do |dir|
        name = File.basename dir
        name = File.basename File.dirname(dir) if name == 'doc'
        @names << name
      end
    end
  end
  
  def copy_files
    @directories.each_with_index do |dir, i|
      name = @names[i]
      index_dir = File.dirname(RDoc::Generator::SHtml::TREE_FILE)
      FileUtils.mkdir_p(File.join @op_dir, name)
      
      Dir.new(dir).each do |item|
        if File.directory?(File.join(dir, item)) && item != '.' && item != '..' && item != index_dir
          FileUtils.cp_r File.join(dir, item), File.join(@op_dir, name, item)
        end
      end
    end
    
    dir = @directories.first
    Dir.new(dir).each do |item|
      if item != '.' && item != '..' && item != RDoc::Generator::SHtml::FILE_DIR && item != RDoc::Generator::SHtml::CLASS_DIR
        FileUtils.cp_r File.join(dir, item), @op_dir
      end
    end
  end
  
  def setup_output_dir
    if File.exists? @op_dir
      error "#{@op_dir} allready exists"
    end
    FileUtils.mkdir_p @op_dir
  end
  
  def check_directories
    @directories.each do |dir|
      unless File.exists?(File.join dir, FLAG_FILE) && 
      File.exists?(File.join dir, RDoc::Generator::SHtml::TREE_FILE) && 
      File.exists?(File.join dir, RDoc::Generator::SHtml::SEARCH_INDEX_FILE)
        error "#{dir} does not seem to be an sdoc directory"
      end
    end
  end
  
  def update_output_dir(op_dir, time)
    File.open(File.join @op_dir, FLAG_FILE, "w") { |f| f.puts time.rfc2822 }
  end
  
  ##
  # Report an error message and exit

  def error(msg)
    raise RDoc::Error, msg
  end
  
end