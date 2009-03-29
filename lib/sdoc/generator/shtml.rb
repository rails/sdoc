require 'rubygems'
require 'json'
require 'pathname'
require 'fileutils'
require 'erb'

require 'rdoc/rdoc'
require 'rdoc/generator'
require 'rdoc/generator/markup'

require 'sdoc/github'

class RDoc::ClassModule
  def with_documentation?
    document_self || classes_and_modules.any?{ |c| c.with_documentation? }
  end
end

class RDoc::Generator::SHtml
  RDoc::RDoc.add_generator( self )
  include ERB::Util
  include SDoc::GitHub
  
  GENERATOR_DIRS = [File.join('sdoc', 'generator'), File.join('rdoc', 'generator')]
  
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
  
  def self.for(options)
    self.new(options)
  end
  
  def initialize(options)
		@options = options
		@options.diagram = false
    @github_url_cache = {}
    
		template = @options.template || 'shtml'

		template_dir = $LOAD_PATH.map do |path|
		  GENERATOR_DIRS.map do |dir|
  			File.join path, dir, 'template', template
	    end
		end.flatten.find do |dir|
			File.directory? dir
		end

		raise RDoc::Error, "could not find template #{template.inspect}" unless
			template_dir
		
		@template_dir = Pathname.new File.expand_path(template_dir)
		@basedir = Pathname.pwd.expand_path
  end
  
  def generate( top_levels )
		@outputdir = Pathname.new( @options.op_dir ).expand_path( @basedir )
		@files = top_levels.sort
		@classes = RDoc::TopLevel.all_classes_and_modules.sort

		# Now actually write the output
    copy_resources
    generate_class_tree
    generate_search_index
		generate_file_files
		generate_class_files
		generate_index_file
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
    tree = generate_class_tree_level topclasses
    debug_msg "  writing class tree to %s" % TREE_FILE
    File.open(TREE_FILE, "w") do |f|
      f.write('var tree = '); f.write(tree.to_json)
    end unless $dryrun
  end
  
  ### Recursivly build class tree structure
  def generate_class_tree_level(classes)
    tree = []
    classes.select{|c| c.with_documentation? }.sort.each do |klass|
      item = [
        klass.name, 
        klass.document_self ? klass.path : '',
        klass.module? ? '' : (klass.superclass ? " < #{String === klass.superclass ? klass.superclass : klass.superclass.full_name}" : ''), 
        generate_class_tree_level(klass.classes_and_modules)
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
    File.open(SEARCH_INDEX_FILE, "w") do |f|
      f.write('var search_data = '); f.write(data.to_json)
    end unless $dryrun
  end
  
  ### Add files to search +index+ array
  def add_file_search_index(index)
    debug_msg "  generating file search index"
    
    @files.select { |method| 
      method.document_self 
    }.sort.each do |file|
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
    
    @classes.select { |method| 
      method.document_self 
    }.sort.each do |klass|
      index[:searchIndex].push( search_string(klass.name) )
      index[:longSearchIndex].push( search_string(klass.parent.name) )
      index[:info].push([
        klass.name, 
        klass.parent.full_name, 
        klass.path, 
        klass.module? ? '' : (klass.superclass ? " < #{String === klass.superclass ? klass.superclass : klass.superclass.full_name}" : ''), 
        snippet(klass.comment),
        TYPE_CLASS
      ])
    end
  end
  
  ### Add methods to search +index+ array
  def add_method_search_index(index)
    debug_msg "  generating method search index"
    
    @classes.map { |klass| 
      klass.method_list 
    }.flatten.sort{ |a, b| a.name <=> b.name }.select { |method| 
      method.document_self 
    }.each do |method|
      index[:searchIndex].push( search_string(method.name) )
      index[:longSearchIndex].push( search_string(method.parent.name) )
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
	
	### Create index.html with frameset
	def generate_index_file
		debug_msg "Generating index file in #@outputdir"
    templatefile = @template_dir + 'index.rhtml'
    outfile      = @outputdir + 'index.html'
	  index_path   = @files.first.path
	  
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
    content.sub(/^(.{100,}?)\s.*/m, "\\1").gsub(/\r?\n/m, ' ')
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
    FileUtils.cp_r resoureces_path.to_s, @outputdir.to_s unless $dryrun
  end
  
	### Load and render the erb template in the given +templatefile+ within the
	### specified +context+ (a Binding object) and return output
	### Both +templatefile+ and +outfile+ should be Pathname-like objects.
  def eval_template(templatefile, context)
		template_src = templatefile.read
		template = ERB.new( template_src, nil, '<>' )
		template.filename = templatefile.to_s

    begin
      template.result( context )
    rescue NoMethodError => err
      raise RDoc::Error, "Error while evaluating %s: %s (at %p)" % [
        templatefile.to_s,
        err.message,
        eval( "_erbout[-50,50]", context )
        ], err.backtrace
      end
  end
  
  ### Load and render the erb template with the given +template_name+ within
  ### current context. Adds all +local_assigns+ to context
  def include_template(template_name, local_assigns = {})
    source = local_assigns.keys.map { |key| "#{key} = local_assigns[:#{key}];" }.join
    eval(source)
    
    templatefile = @template_dir + template_name
    eval_template(templatefile, binding)
  end
  
	### Load and render the erb template in the given +templatefile+ within the
	### specified +context+ (a Binding object) and write it out to +outfile+.
	### Both +templatefile+ and +outfile+ should be Pathname-like objects.
	def render_template( templatefile, context, outfile )
    output = eval_template(templatefile, context)
		unless $dryrun
			outfile.dirname.mkpath
			outfile.open( 'w', 0644 ) do |ofh|
				ofh.print( output )
			end
		else
			debug_msg "  would have written %d bytes to %s" %
			[ output.length, outfile ]
		end
	end  
end

# module Generators
#   # SOURCE_DIR = 'source'
#   
#   module MarkUp
#     def snippetize(str)
#       if str =~ /^(?>\s*)[^\#]/
#         content = str
#       else
#         content = str.gsub(/^\s*(#+)\s*/, '')
#       end
#       content.sub(/^(.{0,100}).*$/m, "\\1").gsub(/\r?\n/m, ' ')
#     end
#   end
#   
#   module CollectMethods
#     def collect_methods
#       list = @context.method_list
#       unless @options.show_all
#         list = list.find_all {|m| m.visibility == :public || m.visibility == :protected || m.force_documentation }
#       end
#       @methods = list.collect {|m| SHtmlMethod.new(m, self, @options) }
#     end
#   end
# 
#   #####################################################################
# 
#   class SHtmlClass < HtmlClass
#     include CollectMethods
#     
#     attr_accessor :children
#     
#     def initialize(context, html_file, prefix, options)
#       super(context, html_file, prefix, options)
#       @children = []
#     end
#     
#     def params
#       @context.superclass ? " < #{@context.superclass}" : ''
#     end
#     
#     def snippet
#       @snippet ||= snippetize(@context.comment)
#     end
#     
#     def namespace
#       @context.parent ? @context.parent.name : ''
#     end
#     
#     def title
#       @context.name
#     end
#     
#     def content?
#       document_self || children.any?{ |c| c.content? }
#     end
#     
#     def path_if_available
#       document_self ? path : ''
#     end
#     
#     def github_url
#       @html_file.github_url
#     end
#   end
# 
#   #####################################################################
# 
#   class SHtmlFile < HtmlFile
#     include CollectMethods
#     
#     attr_accessor :github_url
#     
#     def initialize(context, options, file_dir)
#       super(context, options, file_dir)
#       @github_url = SHTMLGenerator.github_url(@context.file_relative_name, @options) if (@options.github_url)
#     end
#     
#     def params
#       ''
#     end
#     
#     def snippet
#       @snippet ||= snippetize(@context.comment)
#     end
#     
#     def namespace
#       @context.file_absolute_name
#     end
#     
#     def title
#       File.basename(namespace)
#     end
#     
#     def value_hash
#       super
#       @values["github_url"] = github_url if (@options.github_url)
#       @values
#     end
#     
#     def absolute_path
#       @context.file_expanded_path
#     end
#     
#   end
# 
#   #####################################################################
# 
#   class SHtmlMethod < HtmlMethod
#     def snippet
#       @snippet ||= snippetize(@context.comment)
#     end
#     
#     def namespace
#       @html_class.name
#     end
#     
#     def title
#       name
#     end
#     
#     def github_url
#       if @source_code =~ /File\s(\S+), line (\d+)/
#         file = $1
#         line = $2.to_i
#       end
#       url = SHTMLGenerator.github_url(file, @options)
#       unless line.nil? || url.nil?
#         url + "#L#{line}" 
#       else
#         ''
#       end
#     end
#   end
# 
#   #####################################################################
# 
#   class SHTMLGenerator < HTMLGenerator
#     
#     @@github_url_cache = {}
#     
#     def self.github_url(file_relative_name, options)
#       unless @@github_url_cache.has_key? file_relative_name
#         file = AllReferences[file_relative_name]
#         if file.nil?
#           return nil
#         end
#         path = file.absolute_path
#         name = File.basename(file_relative_name)
#         
#         pwd = Dir.pwd
#         Dir.chdir(File.dirname(path))
#         s = `git log -1 --pretty=format:"commit %H" #{name}`
#         Dir.chdir(pwd)
#         
#         m = s.match(/commit\s+(\S+)/)
#         if m
#           repository_path = path_relative_to_repository(path)
#           @@github_url_cache[file_relative_name] = "#{options.github_url}/blob/#{m[1]}#{repository_path}"
#         end
#       end
#       @@github_url_cache[file_relative_name]
#     end
#     
#     def self.path_relative_to_repository(path)
#       root = find_git_dir(path)
#       path[root.size..path.size]
#     end
#     
#     def self.find_git_dir(path)
#       while !path.empty? && path != '.'
#         if (File.exists? File.join(path, '.git')) 
#           return path
#         end
#         path = File.dirname(path)
#       end
#       ''
#     end
#     
# 
#     def SHTMLGenerator.for(options)
#       AllReferences::reset
#       HtmlMethod::reset
# 
#       SHTMLGenerator.new(options)
#     end
#     
#     def load_html_template
#       template = @options.template
#       unless template =~ %r{/|\\}
#         template = File.join("sdoc/generators/template",
#                              @options.generator.key, template)
#       end
#       require template
#       extend RDoc::Page
#     rescue LoadError
#       $stderr.puts "Could not find HTML template '#{template}'"
#       exit 99
#     end
#     
#     def generate_html
#       # the individual descriptions for files and classes
#       gen_into(@files)
#       gen_into(@classes)
#       gen_search_index
#       gen_tree_index
#       gen_main_index
#       copy_resources
#       
#       # this method is defined in the template file
#       write_extra_pages if defined? write_extra_pages
#     end
#     
#     def build_indices
#       @toplevels.each do |toplevel|
#         @files << SHtmlFile.new(toplevel, @options, FILE_DIR)
#       end
#       @topclasses = []
#       RDoc::TopLevel.all_classes_and_modules.each do |cls|
#         @topclasses << build_class_list(cls, @files[0], CLASS_DIR)
#       end
#     end
# 
#     def build_class_list(from, html_file, class_dir)
#       klass = SHtmlClass.new(from, html_file, class_dir, @options)
#       @classes << klass
#       from.each_classmodule do |mod|
#         klass.children << build_class_list(mod, html_file, class_dir)
#       end
#       klass
#     end
#     
#     def copy_resources
#       FileUtils.cp_r RDoc::Page::RESOURCES_PATH, '.'
#     end
#     
#     def search_string(string)
#       string.downcase.gsub(/\s/,'')
#     end
#     
#     def gen_tree_index
#       tree = gen_tree_level @topclasses
#       File.open('tree.yaml', 'w') { |f| f.write(tree.to_yaml) }
#       File.open('tree.js', "w") do |f|
#         f.write('var tree = '); f.write(tree.to_json)
#       end
#     end
#     
#     def gen_tree_level(classes)
#       tree = []
#       classes.select{|c| c.content? }.sort.each do |item|
#         item = [item.title, item.namespace, item.path_if_available, item.params, item.snippet, gen_tree_level(item.children)]
#         tree << item
#       end
#       tree
#     end
#     
#     def gen_search_index
#       entries = HtmlMethod.all_methods.sort
#       entries += @classes.sort
#       entries += @files.sort
#       entries = entries.select { |f| f.document_self }
#       
#       result = {
#         :searchIndex => [],
#         :longSearchIndex => [],
#         :info => []
#       }
#       
#       entries.each_with_index do |item, index|
#         result[:searchIndex].push( search_string(item.title) )
#         result[:longSearchIndex].push( search_string(item.namespace) )
#         result[:info].push([item.title, item.namespace, item.path, item.params, item.snippet])
#       end
#       
#       File.open('index.js', "w") do |f|
#         f.write('var data = '); f.write(result.to_json)
#       end
#       File.open('index.yaml', 'w') { |f| f.write(result.to_yaml) }
#     end
# 
#   end
#   
#   class ContextUser
#     def build_method_detail_list(section)
#       outer = []
# 
#       methods = @methods.sort
#       for singleton in [true, false]
#         for vis in [ :public, :protected, :private ] 
#           res = []
#           methods.each do |m|
#             if m.section == section and
#                 m.document_self and 
#                 m.visibility == vis and 
#                 m.singleton == singleton
#               row = {}
#               if m.call_seq
#                 row["callseq"] = m.call_seq.gsub(/->/, '&rarr;')
#               else
#                 row["name"]        = CGI.escapeHTML(m.name)
#                 row["params"]      = m.params
#               end
#               desc = m.description.strip
#               row["m_desc"]      = desc unless desc.empty?
#               row["aref"]        = m.aref
#               row["visibility"]  = m.visibility.to_s
# 
#               alias_names = []
#               m.aliases.each do |other|
#                 if other.viewer   # won't be if the alias is private
#                   alias_names << {
#                     'name' => other.name,
#                     'aref'  => other.viewer.as_href(path)
#                   } 
#                 end
#               end
#               unless alias_names.empty?
#                 row["aka"] = alias_names
#               end
# 
#               if @options.inline_source
#                 code = m.source_code
#                 row["sourcecode"] = code if code
#                 row["github_url"] = m.github_url if @options.github_url
#               else
#                 code = m.src_url
#                 if code
#                   row["codeurl"] = code
#                   row["imgurl"]  = m.img_url
#                   row["github_url"] = m.github_url if @options.github_url
#                 end
#               end
#               res << row
#             end
#           end
#           if res.size > 0 
#             outer << {
#               "type"    => vis.to_s.capitalize,
#               "category"    => singleton ? "Class" : "Instance",
#               "methods" => res
#             }
#           end
#         end
#       end
#       outer
#     end    
#   end
# end