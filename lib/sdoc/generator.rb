require 'rubygems'
require 'erb'
require 'pathname'
require 'fileutils'
require 'rdoc/markup/to_html'
if Gem.available? "json"
  gem "json", ">= 1.1.3"
else
  gem "json_pure", ">= 1.1.3"
end
require 'json'
require 'sanitize'

require 'sdoc/github'
require 'sdoc/templatable'
require 'sdoc/helpers'
require 'rdoc'
require 'rdoc/rdoc'
require 'rdoc/generator'

class RDoc::ClassModule
  def document_self_or_methods
    document_self || method_list.any?{ |m| m.document_self }
  end

  def with_documentation?
    document_self_or_methods || classes_and_modules.any?{ |c| c.with_documentation? }
  end
end

class RDoc::Options
  attr_accessor :github
  attr_accessor :se_index
end

class RDoc::AnyMethod

  TITLE_AFTER = %w(def class module)

  ##
  # Turns the method's token stream into HTML.
  #
  # Prepends line numbers if +add_line_numbers+ is true.

  def sdoc_markup_code
    return '' unless @token_stream

    src = ""
    starting_title = false

    @token_stream.each do |t|
      next unless t

      style = case t
              when RDoc::RubyToken::TkFLOAT    then 'ruby-number'
              when RDoc::RubyToken::TkINTEGER  then 'ruby-number'
              when RDoc::RubyToken::TkCONSTANT then 'ruby-constant'
              when RDoc::RubyToken::TkKW       then 'ruby-keyword'
              when RDoc::RubyToken::TkIVAR     then 'ruby-ivar'
              when RDoc::RubyToken::TkOp       then 'ruby-operator'
              when RDoc::RubyToken::TkId       then 'ruby-identifier'
              when RDoc::RubyToken::TkNode     then 'ruby-node'
              when RDoc::RubyToken::TkCOMMENT  then 'ruby-comment'
              when RDoc::RubyToken::TkREGEXP   then 'ruby-regexp'
              when RDoc::RubyToken::TkSTRING   then 'ruby-string'
              when RDoc::RubyToken::TkVal      then 'ruby-value'
              end

      if RDoc::RubyToken::TkId === t && starting_title
        starting_title = false
        style = 'ruby-keyword ruby-title'
      end

      if RDoc::RubyToken::TkKW === t && TITLE_AFTER.include?(t.text)
        starting_title = true
      end

      text = CGI.escapeHTML t.text

      if style then
        src << "<span class=\"#{style}\">#{text}</span>"
      else
        src << text
      end
    end

    # dedent the source
    indent = src.length
    lines = src.lines.to_a
    lines.shift if src =~ /\A.*#\ *File/i # remove '# File' comment
    lines.each do |line|
      if line =~ /^ *(?=\S)/
        n = $&.length
        indent = n if n < indent
        break if n == 0
      end
    end
    src.gsub!(/^#{' ' * indent}/, '') if indent > 0

    add_line_numbers(src) if self.class.add_line_numbers

    src
  end

end

class RDoc::Generator::SDoc
  RDoc::RDoc.add_generator self

  DESCRIPTION = 'Searchable HTML documentation'

  include ERB::Util
  include SDoc::GitHub
  include SDoc::Templatable
  include SDoc::Helpers

  GENERATOR_DIRS = [File.join('sdoc', 'generator')]

  # Used in js to reduce index sizes
  TYPE_CLASS  = 1
  TYPE_METHOD = 2
  TYPE_FILE   = 3

  TREE_FILE = File.join 'panel', 'tree.js'
  SEARCH_INDEX_FILE = File.join 'panel', 'search_index.js'

  FILE_DIR = 'files'
  CLASS_DIR = 'classes'

  RESOURCES_DIR = File.join('resources', '.')

  attr_reader :basedir

  attr_reader :options

  def self.setup_options(options)
    @github = false
    options.se_index = true

    opt = options.option_parser
    opt.separator nil
    opt.separator "SDoc generator options:"
    opt.separator nil
    opt.on("--github", "-g",
           "Generate links to github.") do |value|
      options.github = true
    end
    opt.separator nil

    opt.on("--no-se-index", "-ns",
           "Do not generated index file for search engines.",
           "SDoc uses javascript to refrence individual documentation pages.",
           "Search engine crawlers are not smart enough to find all the",
           "referenced pages.",
           "To help them SDoc generates a static file with links to every",
           "documentation page. This file is not shown to the user."
           ) do |value|
      options.se_index = false
    end
    opt.separator nil

  end

  def initialize(options)
    @options = options
    if @options.respond_to?('diagram=')
      @options.diagram = false
    end
    @github_url_cache = {}

    @template_dir = Pathname.new(options.template_dir)
    @basedir = Pathname.pwd.expand_path
  end

  def generate(top_levels)
    @outputdir = Pathname.new(@options.op_dir).expand_path(@basedir)
    @files = top_levels.sort
    @classes = RDoc::TopLevel.all_classes_and_modules.sort

    # Now actually write the output
    copy_resources
    generate_class_tree
    generate_search_index
    generate_file_files
    generate_class_files
    generate_index_file
    generate_se_index if @options.se_index
  end

  def class_dir
    CLASS_DIR
  end

  def file_dir
    FILE_DIR
  end

  protected
  ### Output progress information if debugging is enabled
  def debug_msg( *msg )
    return unless $DEBUG_RDOC
    $stderr.puts( *msg )
  end

  ### Create class tree structure and write it as json
  def generate_class_tree
    debug_msg "Generating class tree"
    topclasses = @classes.select {|klass| !(RDoc::ClassModule === klass.parent) }
    tree = generate_file_tree + generate_class_tree_level(topclasses)
    debug_msg "  writing class tree to %s" % TREE_FILE
    File.open(TREE_FILE, "w", 0644) do |f|
      f.write('var tree = '); f.write(tree.to_json(:max_nesting => 0))
    end unless $dryrun
  end

  ### Recursivly build class tree structure
  def generate_class_tree_level(classes, visited = {})
    tree = []
    classes.select do |klass| 
      !visited[klass] && klass.with_documentation? 
    end.sort.each do |klass|
      visited[klass] = true
      item = [
        klass.name,
        klass.document_self_or_methods ? klass.path : '',
        klass.module? ? '' : (klass.superclass ? " < #{String === klass.superclass ? klass.superclass : klass.superclass.full_name}" : ''),
        generate_class_tree_level(klass.classes_and_modules, visited)
      ]
      tree << item
    end
    tree
  end

  ### Create search index for all classes, methods and files
  ### Wite it as json
  def generate_search_index
    debug_msg "Generating search index"

    index = {
      :searchIndex => [],
      :longSearchIndex => [],
      :info => []
    }

    add_class_search_index(index)
    add_method_search_index(index)
    add_file_search_index(index)

    debug_msg "  writing search index to %s" % SEARCH_INDEX_FILE
    data = {
      :index => index
    }
    File.open(SEARCH_INDEX_FILE, "w", 0644) do |f|
      f.write('var search_data = '); f.write(data.to_json(:max_nesting => 0))
    end unless $dryrun
  end

  ### Add files to search +index+ array
  def add_file_search_index(index)
    debug_msg "  generating file search index"

    @files.select { |file|
      file.document_self
    }.sort.each do |file|
      debug_msg "    #{file.path}"
      index[:searchIndex].push( search_string(file.name) )
      index[:longSearchIndex].push( search_string(file.path) )
      index[:info].push([
        file.name,
        file.path,
        file.path,
        '',
        snippet(file.comment),
        TYPE_FILE
      ])
    end
  end

  ### Add classes to search +index+ array
  def add_class_search_index(index)
    debug_msg "  generating class search index"
    @classes.uniq.select { |klass|
      klass.document_self_or_methods
    }.sort.each do |klass|
      modulename = klass.module? ? '' : (klass.superclass ? (String === klass.superclass ? klass.superclass : klass.superclass.full_name) : '')
      debug_msg "    #{klass.parent.full_name}::#{klass.name}"
      index[:searchIndex].push( search_string(klass.name) )
      index[:longSearchIndex].push( search_string(klass.parent.full_name) )
      files = klass.in_files.map{ |file| file.absolute_name }
      index[:info].push([
        klass.name,
        files.include?(klass.parent.full_name) ? files.first : klass.parent.full_name,
        klass.path,
        modulename ? " < #{modulename}" : '',
        snippet(klass.comment),
        TYPE_CLASS
      ])
    end
  end

  ### Add methods to search +index+ array
  def add_method_search_index(index)
    debug_msg "  generating method search index"

    list = @classes.uniq.map do |klass|
      klass.method_list
    end.flatten.sort do |a, b|
      a.name == b.name ?
        a.parent.full_name <=> b.parent.full_name :
        a.name <=> b.name
    end.select do |method|
      method.document_self
    end.find_all do |m|
      m.visibility == :public || m.visibility == :protected ||
      m.force_documentation
    end

    list.each do |method|
      debug_msg "    #{method.full_name}"
      index[:searchIndex].push( search_string(method.name) + '()' )
      index[:longSearchIndex].push( search_string(method.parent.full_name) )
      index[:info].push([
        method.name,
        method.parent.full_name,
        method.path,
        method.params,
        snippet(method.comment),
        TYPE_METHOD
      ])
    end
  end

  ### Generate a documentation file for each class
  def generate_class_files
    debug_msg "Generating class documentation in #@outputdir"
    templatefile = @template_dir + 'class.rhtml'

    @classes.each do |klass|
      debug_msg "  working on %s (%s)" % [ klass.full_name, klass.path ]
      outfile     = @outputdir + klass.path
      rel_prefix  = @outputdir.relative_path_from( outfile.dirname )

      debug_msg "  rendering #{outfile}"
      self.render_template( templatefile, binding(), outfile )
    end
  end

  ### Generate a documentation file for each file
  def generate_file_files
    debug_msg "Generating file documentation in #@outputdir"
    templatefile = @template_dir + 'file.rhtml'

    @files.each do |file|
      outfile     = @outputdir + file.path
      debug_msg "  working on %s (%s)" % [ file.full_name, outfile ]
      rel_prefix  = @outputdir.relative_path_from( outfile.dirname )

      debug_msg "  rendering #{outfile}"
      self.render_template( templatefile, binding(), outfile )
    end
  end

  ### Determines index path based on @options.main_page (or lack thereof)
  def index_path
    # Break early to avoid a big if block when no main page is specified
    default = @files.first.path
    return default unless @options.main_page

    # Transform class name to file path
    if @options.main_page.include?("::")
      slashed = @options.main_page.sub(/^::/, "").gsub("::", "/")
      "%s/%s.html" % [ class_dir, slashed ]
    elsif file = @files.find { |f| f.full_name == @options.main_page }
      file.path
    else
      default
    end
  end

  ### Create index.html with frameset
  def generate_index_file
    debug_msg "Generating index file in #@outputdir"
    templatefile = @template_dir + 'index.rhtml'
    outfile      = @outputdir + 'index.html'

    self.render_template( templatefile, binding(), outfile )
  end

  ### Generate file with links for the search engine
  def generate_se_index
    debug_msg "Generating search engine index in #@outputdir"
    templatefile = @template_dir + 'se_index.rhtml'
    outfile      = @outputdir + 'panel/links.html'

    self.render_template( templatefile, binding(), outfile )
  end

  ### Strip comments on a space after 100 chars
  def snippet(str)

    str ||= ''
    if str =~ /^(?>\s*)[^\#]/
      content = str
    else
      content = str.gsub(/^\s*(#+)\s*/, '')
    end

    # Get a plain string with no markup.
    content = Sanitize.clean(RDoc::Markup::ToHtml.new.convert(content))
    content = content.sub(/^(.{100,}?)\s.*/m, "\\1").gsub(/\r?\n/m, ' ')

    begin
      content.to_json(:max_nesting => 0)
    rescue # might fail on non-unicode string
      begin
        content = Iconv.conv('latin1//ignore', "UTF8", content) # remove all non-unicode chars
        content.to_json(:max_nesting => 0)
      rescue
        content = '' # something hugely wrong happend
      end
    end
    content
  end

  ### Build search index key
  def search_string(string)
    string ||= ''
    string.downcase.gsub(/\s/,'')
  end

  ### Copy all the resource files to output dir
  def copy_resources
    resoureces_path = @template_dir + RESOURCES_DIR
    debug_msg "Copying #{resoureces_path}/** to #{@outputdir}/**"
    FileUtils.cp_r resoureces_path.to_s, @outputdir.to_s, :preserve => true unless $dryrun
  end

  class FilesTree
    attr_reader :children
    def add(path, url)
      path = path.split(File::SEPARATOR) unless Array === path
      @children ||= {}
      if path.length == 1
        @children[path.first] = url
      else
        @children[path.first] ||= FilesTree.new
        @children[path.first].add(path[1, path.length], url)
      end
    end
  end

  def generate_file_tree
    if @files.length > 1
      @files_tree = FilesTree.new
      @files.each do |file|
        @files_tree.add(file.relative_name, file.path)
      end
      [['', '', 'files', generate_file_tree_level(@files_tree)]]
    else
      []
    end
  end

  def generate_file_tree_level(tree)
    tree.children.keys.sort.map do |name|
      child = tree.children[name]
      if String === child
        [name, child, '', []]
      else
        ['', '', name, generate_file_tree_level(child)]
      end
    end
  end
end
