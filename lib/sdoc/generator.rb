require 'pathname'
require 'fileutils'
require 'json'

require "rdoc"
require_relative "rdoc_monkey_patches"

require "sdoc/postprocessor"
require "sdoc/renderer"
require "sdoc/search_index"
require "sdoc/version"

class RDoc::Options
  attr_writer :core_ext_pattern

  def core_ext_pattern
    @core_ext_pattern ||= /core_ext/
  end

  attr_accessor :github
end

class RDoc::Generator::SDoc
  RDoc::RDoc.add_generator self

  DESCRIPTION = 'Searchable HTML documentation'

  FILE_DIR = 'files'
  CLASS_DIR = 'classes'

  RESOURCES_DIR = File.join('resources', '.')

  attr_reader :options

  ##
  # The RDoc::Store that is the source of the generated content

  attr_reader :store

  def self.setup_options(options)
    opt = options.option_parser

    opt.separator nil
    opt.separator "SDoc generator options:"

    opt.separator nil
    opt.on("--core-ext=PATTERN", Regexp, "Regexp pattern indicating files that define core extensions. " \
      "Defaults to 'core_ext'.") do |pattern|
      options.core_ext_pattern = pattern
    end

    opt.separator nil
    opt.on("--github", "-g",
            "Generate links to github.") do |value|
      options.github = true
    end

    opt.separator nil
    opt.on("--version", "-v", "Output current version") do
      puts SDoc::VERSION
      exit
    end

    options.title = [
      ENV["HORO_PROJECT_NAME"],
      ENV["HORO_BADGE_VERSION"] || ENV["HORO_PROJECT_VERSION"],
      "API documentation"
    ].compact.join(" ")
  end

  def initialize(store, options)
    @store   = store
    @options = options
    if @options.respond_to?('diagram=')
      @options.diagram = false
    end
    @options.pipe = true

    @original_dir = Pathname.pwd
    @template_dir = Pathname(options.template_dir)
    @output_dir = Pathname(@options.op_dir).expand_path(options.root)
  end

  def generate
    @files = @store.all_files.sort
    @classes = @store.all_classes_and_modules.sort

    FileUtils.mkdir_p(@output_dir)
    copy_resources
    generate_search_index
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

  ### Determines index page based on @options.main_page (or lack thereof)
  def index
    @index ||= begin
      path = @original_dir.join(@options.main_page || @options.files.first || "").expand_path
      file = @files.find { |file| @options.root.join(file.full_name) == path }
      raise "Could not find main page #{path.to_s.inspect} among rendered files" if !file

      file = file.dup
      file.path = ""

      file
    end
  end

  protected
  ### Output progress information if debugging is enabled
  def debug_msg(*msg)
    $stderr.puts(*msg) if $DEBUG_RDOC
  end

  def render_file(template_path, output_path, context = nil)
    debug_msg "Rendering #{output_path}"
    return if @options.dry_run

    result = SDoc::Renderer.new(context, @options).render(template_path)
    result = SDoc::Postprocessor.process(result)

    output_path = @output_dir.join(output_path)
    output_path.dirname.mkpath
    output_path.write(result)
  end

  def generate_index_file
    render_file("index.rhtml", "index.html", index)
  end

  def generate_class_files
    @classes.each { |klass| render_file("class.rhtml", klass.path, klass) }
  end

  def generate_file_files
    @files.each { |file| render_file("file.rhtml", file.path, file) }
  end

  def generate_search_index
    debug_msg "Generating search index"
    unless @options.dry_run
      index = SDoc::SearchIndex.generate(@store.all_classes_and_modules)

      @output_dir.join("js/search-index.js").open("w") do |file|
        file.write("export default ")
        JSON.dump(index, file)
        file.write(";")
      end
    end
  end

  ### Copy all the resource files to output dir
  def copy_resources
    resources_path = @template_dir + RESOURCES_DIR
    debug_msg "Copying #{resources_path}/** to #{@output_dir}/**"
    FileUtils.cp_r resources_path.to_s, @output_dir.to_s unless @options.dry_run
  end
end
