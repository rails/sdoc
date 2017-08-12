require 'erb'
require 'pathname'
require 'fileutils'
require 'json'

require 'sdoc/github'
require 'sdoc/templatable'
require 'sdoc/helpers'
require 'rdoc'

class RDoc::ClassModule
  def with_documentation?
    document_self_or_methods || classes_and_modules.any?{ |c| c.with_documentation? }
  end
end

class RDoc::Options
  attr_accessor :github
  attr_accessor :search_index
end

class RDoc::Generator::SDoc
  RDoc::RDoc.add_generator self

  DESCRIPTION = 'Searchable HTML documentation'

  include ERB::Util
  include SDoc::GitHub
  include SDoc::Templatable
  include SDoc::Helpers

  GENERATOR_DIRS = [File.join('sdoc', 'generator')]

  TREE_FILE = File.join 'panel', 'tree.js'
  SEARCH_INDEX_FILE = File.join 'js', 'search_index.js'

  FILE_DIR = 'files'
  CLASS_DIR = 'classes'

  RESOURCES_DIR = File.join('resources', '.')

  attr_reader :base_dir

  attr_reader :options

  ##
  # The RDoc::Store that is the source of the generated content

  attr_reader :store

  def self.setup_options(options)
    opt = options.option_parser
    opt.separator nil
    opt.separator "SDoc generator options:"
    opt.separator nil
    opt.on("--github", "-g",
            "Generate links to github.") do |value|
      options.github = true
    end
    opt.separator nil

  end

  def initialize(store, options)
    @store   = store
    @options = options
    if @options.respond_to?('diagram=')
      @options.diagram = false
    end
    @options.pipe = true
    @github_url_cache = {}

    @template_dir = Pathname.new(options.template_dir)
    @base_dir = Pathname.pwd.expand_path

    @json_index = RDoc::Generator::JsonIndex.new self, options
  end

  def generate
    @outputdir = Pathname.new(@options.op_dir).expand_path(@base_dir)
    @files = @store.all_files.sort
    @classes = @store.all_classes_and_modules.sort

    # Now actually write the output
    copy_resources
    @json_index.generate
    @json_index.generate_gzipped
    generate_search_index
    generate_class_tree

    generate_index_file
    generate_file_files
    generate_class_files
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

  ### Create index.html with frameset
  def generate_index_file
    debug_msg "Generating index file in #@outputdir"
    templatefile = @template_dir + 'index.rhtml'
    outfile      = @outputdir + 'index.html'

    self.render_template( templatefile, binding(), outfile ) unless @options.dry_run
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
      self.render_template( templatefile, binding(), outfile ) unless @options.dry_run
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
      self.render_template( templatefile, binding(), outfile ) unless @options.dry_run
    end
  end

  ### Generate file with links for the search engine
  def generate_search_index
    debug_msg "Generating search engine index in #@outputdir"
    templatefile = @template_dir + 'search_index.rhtml'
    outfile      = @outputdir + 'panel/links.html'

    self.render_template( templatefile, binding(), outfile ) unless @options.dry_run
  end

  ### Create class tree structure and write it as json
  def generate_class_tree
    debug_msg "Generating class tree"
    topclasses = @classes.select {|klass| !(RDoc::ClassModule === klass.parent) }
    tree = generate_file_tree + generate_class_tree_level(topclasses)
    debug_msg "  writing class tree to %s" % TREE_FILE
    File.open(TREE_FILE, "w", 0644) do |f|
      f.write('var tree = '); f.write(tree.to_json(:max_nesting => 0))
    end unless @options.dry_run
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

  ### Copy all the resource files to output dir
  def copy_resources
    resources_path = @template_dir + RESOURCES_DIR
    debug_msg "Copying #{resources_path}/** to #{@outputdir}/**"
    FileUtils.cp_r resources_path.to_s, @outputdir.to_s unless @options.dry_run
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
