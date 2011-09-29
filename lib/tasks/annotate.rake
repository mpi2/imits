namespace :annotate do

  def delete_lines_at_end_of_files(filenames)
    Dir.chdir Rails.root do
      filenames.each do |filename|
        lines = File.read(filename).lines.to_a
        while(lines.size != 0 and lines.last.blank?)
          lines.delete_at(-1)
        end
        new_contents = lines.join ''
        new_contents << "\n" unless new_contents.empty? or new_contents.last == "\n"
        File.open(filename, 'w') {|f| f.write new_contents }
      end
    end
  end

  # Courtesy of http://sed.sourceforge.net/sed1line.txt
  SED_DELETE_TRAILING_BLANK_LINES = '-e :a -e \'/^\n*$/{$d;N;ba\' -e \'}\''

  desc "Remove all annotation and clean up stray whitespace left by annoying annotate gem"
  task :remove do
    system("cd #{Rails.root}; bundle exec annotate -d")
    delete_lines_at_end_of_files(Dir['test/fixtures/**/*.yml'] + Dir['app/models/**/*.rb'])
  end

  desc "Add/update models with new annotation"
  task :models => [:remove] do
    system("cd #{Rails.root}; bundle exec annotate -e tests,fixtures -i")
    delete_lines_at_end_of_files(Dir['test/fixtures/**/*.yml'])
  end
end

desc "Add/update models with new annotation"
task :annotate => ['annotate:models']
