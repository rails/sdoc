# frozen_string_literal: true

class RDoc::Generator::NameList

  include RDoc::Text

  attr_reader :index # :nodoc:

  RDoc::RDoc.add_generator self

  ##
  # Creates a new generator.

  def initialize store, options
    @store            = store
    @options          = options

    @classes = nil
    @files   = nil
    @index   = nil
  end

  ##
  # Builds the list of namespaces and methods as a Hash.

  def build_index
    reset @store.all_files.sort, @store.all_classes_and_modules.sort

    index_classes
    index_methods

    { :index => @index }
  end

  ##
  # Output progress information if debugging is enabled

  def debug_msg *msg
    return unless $DEBUG_RDOC
    $stderr.puts(*msg)
  end

  ##
  # Writes the name list to disk

  def generate
    debug_msg "Generating Name List"
    data = build_index

    return if @options.dry_run

    out_dir = Pathname.new "."

    FileUtils.mkdir_p out_dir, :verbose => $DEBUG_RDOC

    generate_classes_index data[:index][:classes], out_dir
    generate_methods_index data[:index][:methods], out_dir
  end

  def generate_classes_index data, out_dir
    classes_file = out_dir + File.join("classes")

    debug_msg "  writing classes index to %s" % classes_file
    classes_file.open 'w', 0644 do |io|
      io.set_encoding Encoding::UTF_8

      io.puts data
    end
  end

  def generate_methods_index data, out_dir
    methods_file = out_dir + File.join("methods")

    debug_msg "  writing methods index to %s" % methods_file
    methods_file.open 'w', 0644 do |io|
      io.set_encoding Encoding::UTF_8

      io.puts data
    end
  end

  ##
  # Adds classes and modules to the index

  def index_classes
    debug_msg "  generating class name index"

    documented = @classes.uniq.select do |klass|
      klass.document_self_or_methods
    end.flatten.sort_by(&:full_name)

    documented.each do |klass|
      debug_msg "    #{klass.full_name}"
      @index[:classes] << "#{klass.full_name}"
    end
  end

  ##
  # Adds methods to the index

  def index_methods
    debug_msg "  generating method name index"

    list = @classes.uniq.map do |klass|
      klass.method_list
    end.flatten.sort_by do |method|
      [method.parent.full_name, method.type, method.name]
    end

    list.each do |method|
      debug_msg "    #{method.full_name}"
      @index[:methods] << "#{method.full_name}"
    end
  end

  def class_dir # :nodoc:
    nil
  end

  def file_dir # :nodoc:
    nil
  end

  def reset files, classes # :nodoc:
    @files   = files
    @classes = classes

    @index = {
      :classes => [],
      :methods => []
    }
  end
end
