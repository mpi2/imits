class ExtjsAutodep
  def self.as_yaml
    class_file_names = nil

    Dir.chdir('public/javascripts') do
      classes = Set.new

      Dir['Imits/**/*.js'].each do |jsfile|
        next unless File.file?(jsfile)
        matches = File.read(jsfile).scan(/('|")((Ext\.ux|Imits)\.[A-Za-z0-9\._]+)('|")/).map {|i| i[1]}
        classes.merge(matches)
      end

      class_file_names = classes.map do |class_name|
        if class_name.match /^Imits/
          'public/javascripts/' + class_name.gsub('.', '/') + '.js'
        else
          'public/extjs/examples/' + class_name.gsub(/^Ext\./, '').gsub('.', '/') + '.js'
        end
      end
    end

    return '[' + class_file_names.map {|f| '"' + f + '"'}.join(', ') + ']'
  end

end
