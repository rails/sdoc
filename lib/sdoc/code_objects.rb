require "rdoc/code_objects"

module RDoc
  class TopLevel
    attr_accessor :file_expanded_path
    
    def initialize(file_name)
      super()
      @name = "TopLevel"
      @file_relative_name = file_name
      @file_absolute_name = file_name
      @file_expanded_path = File.expand_path(file_name)
      @file_stat          = File.stat(file_name)
      @diagram            = nil
    end
  end
end