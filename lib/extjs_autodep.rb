class ExtjsAutodep
  class Klass
    class FileNotFoundError < RuntimeError; end
    def self.get(name)
      if ! @@pool.has_key?(name)
        @@pool[name] = self.new(name)
      end

      return @@pool[name]
    end

    def initialize(name)
      if @@pool.has_key?(name)
        raise "Already have klass #{name} in pool"
      end
      @name = name

      if name.match /^Imits\./
        @file = 'public/javascripts/' + name.gsub('.', '/') + '.js'
      else
        @file = 'public/extjs/examples/' + name.gsub(/^Ext\./, '').gsub('.', '/') + '.js'
      end

      if ! File.exist?(@file)
        raise FileNotFoundError
      end

      init_dependencies
    end

    attr_reader :name, :file, :dependencies

    def init_dependencies
      @dependencies = []
      klass_names = File.read(file).scan(/('|")((Ext\.ux|Imits)\.[A-Za-z0-9\._]+)('|")/).map {|i| i[1]}
      klass_names.delete self.name
      klass_names.each do |klass_name|
        begin
          klass = self.class.get(klass_name)
        rescue Klass::FileNotFoundError
          if klass_name.match /^Ext\.ux/
            next
          else
            raise
          end
        end
        @dependencies.push klass
      end
    end
    private :init_dependencies

    @@pool = {}
  end

  class KlassDependencyResolver
    def initialize
      @klass_list = []
    end

    attr_reader :klass_list

    def generate_klass_list_for_klass(klass)
      return if @klass_list.include? klass

      klass.dependencies.each do |dep_klass|
        generate_klass_list_for_klass(dep_klass)
      end

      @klass_list.push klass
    end

    def traverse(files)
      klass_names = files.map do |file|
        md = file.match(%r{^public/javascripts/(Imits/.+)\.js$})
        raise 'File must be in public/javascripts/Imits' unless md
        md[1].gsub('/', '.')
      end

      klass_names.each {|k| generate_klass_list_for_klass(Klass.get(k)) }
    end
  end

  def self.resolve_deps
    resolver = KlassDependencyResolver.new
    resolver.traverse(Dir['public/javascripts/Imits/**/*.js'])
    return resolver.klass_list
  end

  def self.as_yaml
    return '[' + self.resolve_deps.map {|i| '"' + i.file + '"'}.join(', ') + ']'
  end

end
