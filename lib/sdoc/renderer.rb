require "erb"
require_relative "helpers"

class SDoc::Renderer
  include SDoc::Helpers

  def self.compile_erb(path)
    @compiled_erb ||= {}
    @compiled_erb[path] ||= begin
      erb = ERB.new(File.read(path), trim_mode: "<>")
      erb.filename = path
      erb
    end
  end

  def initialize(context, rdoc_options)
    @context = context
    @options = rdoc_options
  end

  def render(template_path, local_assigns = {})
    template_path = File.expand_path(template_path, @options.template_dir)
    _binding = binding
    local_assigns.each { |name, value| _binding.local_variable_set(name, value) }
    self.class.compile_erb(template_path).result(_binding)
  end
end
