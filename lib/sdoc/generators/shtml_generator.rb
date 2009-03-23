require 'rubygems'
require 'json'
require 'fileutils'
require 'rdoc/generators/html_generator'


module Generators
  # SOURCE_DIR = 'source'
  
  module MarkUp
    def snippetize(str)
      if str =~ /^(?>\s*)[^\#]/
        content = str
      else
        content = str.gsub(/^\s*(#+)\s*/, '')
      end
      content.sub(/^(.{0,100}).*$/m, "\\1").gsub(/\r?\n/m, ' ')
    end
  end
  
  module CollectMethods
    def collect_methods
      list = @context.method_list
      unless @options.show_all
        list = list.find_all {|m| m.visibility == :public || m.visibility == :protected || m.force_documentation }
      end
      @methods = list.collect {|m| SHtmlMethod.new(m, self, @options) }
    end
  end

  #####################################################################

  class SHtmlClass < HtmlClass
    include CollectMethods
    
    attr_accessor :children
    
    def initialize(context, html_file, prefix, options)
      super(context, html_file, prefix, options)
      @children = []
    end
    
    def params
      @context.superclass ? " < #{@context.superclass}" : ''
    end
    
    def snippet
      @snippet ||= snippetize(@context.comment)
    end
    
    def namespace
      @context.parent ? @context.parent.name : ''
    end
    
    def title
      @context.name
    end
    
    def content?
      document_self || children.any?{ |c| c.content? }
    end
    
    def path_if_available
      document_self ? path : ''
    end
    
    def github_url
      @html_file.github_url
    end
  end

  #####################################################################

  class SHtmlFile < HtmlFile
    include CollectMethods
    
    attr_accessor :github_url
    
    def initialize(context, options, file_dir)
      super(context, options, file_dir)
      @github_url = SHTMLGenerator.github_url(@context.file_relative_name, @options) if (@options.github_url)
    end
    
    def params
      ''
    end
    
    def snippet
      @snippet ||= snippetize(@context.comment)
    end
    
    def namespace
      @context.file_absolute_name
    end
    
    def title
      File.basename(namespace)
    end
    
    def value_hash
      super
      @values["github_url"] = github_url if (@options.github_url)
      @values
    end
    
    def absolute_path
      @context.file_expanded_path
    end
    
  end

  #####################################################################

  class SHtmlMethod < HtmlMethod
    def snippet
      @snippet ||= snippetize(@context.comment)
    end
    
    def namespace
      @html_class.name
    end
    
    def title
      name
    end
    
    def github_url
      if @source_code =~ /File\s(\S+), line (\d+)/
        file = $1
        line = $2.to_i
      end
      url = SHTMLGenerator.github_url(file, @options)
      unless line.nil? || url.nil?
        url + "#L#{line}" 
      else
        ''
      end
    end
  end

  #####################################################################

  class SHTMLGenerator < HTMLGenerator
    
    @@github_url_cache = {}
    
    def self.github_url(file_relative_name, options)
      unless @@github_url_cache.has_key? file_relative_name
        file = AllReferences[file_relative_name]
        if file.nil?
          return nil
        end
        path = file.absolute_path
        name = File.basename(file_relative_name)
        
        pwd = Dir.pwd
        Dir.chdir(File.dirname(path))
        s = `git log -1 --pretty=format:"commit %H" #{name}`
        Dir.chdir(pwd)
        
        m = s.match(/commit\s+(\S+)/)
        if m
          repository_path = path_relative_to_repository(path)
          @@github_url_cache[file_relative_name] = "#{options.github_url}/blob/#{m[1]}#{repository_path}"
        end
      end
      @@github_url_cache[file_relative_name]
    end
    
    def self.path_relative_to_repository(path)
      root = find_git_dir(path)
      path[root.size..path.size]
    end
    
    def self.find_git_dir(path)
      while !path.empty? && path != '.'
        if (File.exists? File.join(path, '.git')) 
          return path
        end
        path = File.dirname(path)
      end
      ''
    end
    

    def SHTMLGenerator.for(options)
      AllReferences::reset
      HtmlMethod::reset

      SHTMLGenerator.new(options)
    end
    
    def load_html_template
      template = @options.template
      unless template =~ %r{/|\\}
        template = File.join("sdoc/generators/template",
                             @options.generator.key, template)
      end
      require template
      extend RDoc::Page
    rescue LoadError
      $stderr.puts "Could not find HTML template '#{template}'"
      exit 99
    end
    
    def generate_html
      # the individual descriptions for files and classes
      gen_into(@files)
      gen_into(@classes)
      gen_search_index
      gen_tree_index
      gen_main_index
      copy_resources
      
      # this method is defined in the template file
      write_extra_pages if defined? write_extra_pages
    end
    
    def build_indices
      @toplevels.each do |toplevel|
        @files << SHtmlFile.new(toplevel, @options, FILE_DIR)
      end
      @topclasses = []
      RDoc::TopLevel.all_classes_and_modules.each do |cls|
        @topclasses << build_class_list(cls, @files[0], CLASS_DIR)
      end
    end

    def build_class_list(from, html_file, class_dir)
      klass = SHtmlClass.new(from, html_file, class_dir, @options)
      @classes << klass
      from.each_classmodule do |mod|
        klass.children << build_class_list(mod, html_file, class_dir)
      end
      klass
    end
    
    def copy_resources
      FileUtils.cp_r RDoc::Page::RESOURCES_PATH, '.'
    end
    
    def search_string(string)
      string.downcase.gsub(/\s/,'')
    end
    
    def gen_tree_index
      tree = gen_tree_level @topclasses
      File.open('tree.yaml', 'w') { |f| f.write(tree.to_yaml) }
      File.open('tree.js', "w") do |f|
        f.write('var tree = '); f.write(tree.to_json)
      end
    end
    
    def gen_tree_level(classes)
      tree = []
      classes.select{|c| c.content? }.sort.each do |item|
        item = [item.title, item.namespace, item.path_if_available, item.params, item.snippet, gen_tree_level(item.children)]
        tree << item
      end
      tree
    end
    
    def gen_search_index
      entries = HtmlMethod.all_methods.sort
      entries += @classes.sort
      entries += @files.sort
      entries = entries.select { |f| f.document_self }
      
      result = {
        :searchIndex => [],
        :longSearchIndex => [],
        :info => []
      }
      
      entries.each_with_index do |item, index|
        result[:searchIndex].push( search_string(item.title) )
        result[:longSearchIndex].push( search_string(item.namespace) )
        result[:info].push([item.title, item.namespace, item.path, item.params, item.snippet])
      end
      
      File.open('index.js', "w") do |f|
        f.write('var data = '); f.write(result.to_json)
      end
      File.open('index.yaml', 'w') { |f| f.write(result.to_yaml) }
    end

  end
  
  class ContextUser
    def build_method_detail_list(section)
      outer = []

      methods = @methods.sort
      for singleton in [true, false]
        for vis in [ :public, :protected, :private ] 
          res = []
          methods.each do |m|
            if m.section == section and
                m.document_self and 
                m.visibility == vis and 
                m.singleton == singleton
              row = {}
              if m.call_seq
                row["callseq"] = m.call_seq.gsub(/->/, '&rarr;')
              else
                row["name"]        = CGI.escapeHTML(m.name)
                row["params"]      = m.params
              end
              desc = m.description.strip
              row["m_desc"]      = desc unless desc.empty?
              row["aref"]        = m.aref
              row["visibility"]  = m.visibility.to_s

              alias_names = []
              m.aliases.each do |other|
                if other.viewer   # won't be if the alias is private
                  alias_names << {
                    'name' => other.name,
                    'aref'  => other.viewer.as_href(path)
                  } 
                end
              end
              unless alias_names.empty?
                row["aka"] = alias_names
              end

              if @options.inline_source
                code = m.source_code
                row["sourcecode"] = code if code
                row["github_url"] = m.github_url if @options.github_url
              else
                code = m.src_url
                if code
                  row["codeurl"] = code
                  row["imgurl"]  = m.img_url
                  row["github_url"] = m.github_url if @options.github_url
                end
              end
              res << row
            end
          end
          if res.size > 0 
            outer << {
              "type"    => vis.to_s.capitalize,
              "category"    => singleton ? "Class" : "Instance",
              "methods" => res
            }
          end
        end
      end
      outer
    end    
  end
end