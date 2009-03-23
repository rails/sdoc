require "rdoc/options"

# Add a github_url option to rdoc options
module SDoc
  class Options < Options
    include Singleton
    
    attr_accessor :github_url

    def parse(argv, generators)
      old_argv = ARGV.dup
      begin
        ARGV.replace(argv)
        @github_url = nil
        
        generator_set = false
        template_set = false

        go = GetoptLong.new(*OptionList.options)
        go.quiet = true

        go.each do |opt, arg|  
          case opt
            when "--github_url"  then @github_url = arg
            when "--fmt"         then generator_set = true
            when "--template"    then template_set = true
          end
        end
      ensure
        ARGV.replace(old_argv)
      end
      super(argv, generators)
      
      unless generator_set
        @generator_name = 'shtml'
        setup_generator(generators)
      end
      
      unless template_set
        @template = @generator_name
      end
    end
    
    def setup_generator(generators)
      if @generator_name == 'shtml'
        @all_one_file = false
      end
      super(generators)
    end
  end
  
end

Options::OptionList::OPTION_LIST << ['--github_url', '-G', 'url', 'Github url prefix like http://github.com/rails/rails']

class Options
  def self.instance
    SDoc::Options.instance
  end
end

