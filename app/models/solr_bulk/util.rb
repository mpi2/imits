
require 'pp'
require 'fileutils'

module SolrBulk

  module Util
    LEGAL_EXTENSIONS = ['.csv']
    TARGETS = []    #[8257, 10515, 10999, 17083, 17721, 18509]
    TYPES = %W{gene phenotype_attempt mi_attempt allele}

    ## sort keys
    ## sort values
    ## remove empty columns
    #def self.normalize_csv(filename, types = TYPES)
    #  raise "#### cannot find file '#{filename}'" if ! File.exists?(filename)
    #  raise "#### illegal file extension detected '#{filename}' ('#{File.extname(filename)}')" if ! LEGAL_EXTENSIONS.include? File.extname(filename)
    #
    #  #puts "#### types: #{types}".green
    #
    #  array = []
    #  counter = 0
    #  headers = nil
    #  CSV.foreach(filename, :headers => true) do |row|
    #    headers = row.headers if headers.nil?
    #    hash = Hash[row.headers[0..-1].zip(row.fields[0..-1])]
    #    array.push hash if (TARGETS.empty? || TARGETS.include?(hash['id'].to_i)) && (types.empty? || types.include?(hash['type']))
    #    counter += 1
    #  end
    #
    #  if array.size == 0
    #    puts "#### cannot find targets in '#{filename}'".red
    #    exit
    #  end
    #
    #  split_targets = %W{project_ids project_statuses project_pipelines vector_project_statuses vector_project_ids}
    #  humanize_targets = %W{project_statuses vector_project_statuses status}
    #  humanize_targets2 = %W{status}
    #  date_targets = %W{effective_date}
    #
    #  headers = headers.sort
    #
    #  array2 = []
    #  empty_hash = {}
    #  allele_name_counter = 0
    #  array.each do |line|
    #
    #    if types.include?('allele') && line['type'] == 'allele'
    #      if line['allele_name'].to_s =~ /\<sup\>\<\/sup\>/
    #        #puts "#### before: #{line['allele_name']}"
    #        line['allele_name'] = nil
    #        #puts "#### after: #{line['allele_name']}"
    #        allele_name_counter += 1
    #      end
    #    end
    #
    #
    #
    #
    #
    #    if types.include?('mi_attempt') && line['type'] == 'mi_attempt'
    #      if ! MiAttempt.find(line['id']).report_to_public
    #        puts "#### mi_attempt ignoring #{line['id']}".red
    #        next
    #      end
    #
    #      #puts line['order_from_names'] if line['order_from_names']
    #      #puts line['order_from_urls'] if line['order_from_urls']
    #
    #      #exit if line['order_from_urls']
    #
    #      line['order_from_names'] = line['order_from_names'].to_s.split(',')
    #      line['order_from_urls'] = line['order_from_urls'].to_s.split(',')
    #
    #      line['order_from_names'] = line['order_from_names'].sort.uniq
    #      line['order_from_urls'] = line['order_from_urls'].sort.uniq
    #
    #      #pp line['order_from_names'] if line['order_from_names']
    #      #pp line['order_from_urls'] if line['order_from_urls']
    #    end
    #
    #
    #
    #    ohash = ActiveSupport::OrderedHash.new
    #    headers.each do |column|
    #      ohash[column] = line[column]
    #      empty_hash[column] ||= false
    #      target = line[column].to_s
    #      target = target.strip || target
    #      empty_hash[column] = empty_hash[column] || target.to_s.length > 0
    #
    #
    #
    #
    #
    #      if split_targets.include? column
    #        split = line[column].to_s.split ','
    #
    #
    #
    #        #if humanize_targets.include? column
    #        #  for i in 0..split.length
    #        #    split[i] = split.to_s.gsub(' -', '').gsub(' ', '_').gsub('-', '').downcase.humanize
    #        #  end
    #        #end
    #
    #
    #        ohash[column] = split.sort.join '|'
    #
    #        if humanize_targets.include? column
    #          ohash[column] = ohash[column].to_s.gsub(' -', '').gsub(' ', '_').gsub('-', '').downcase
    #        end
    #      end
    #
    #      if humanize_targets2.include? column
    #        ohash[column] = ohash[column].to_s.gsub(' -', '').gsub(' ', '_').gsub('-', '').downcase
    #      end
    #
    #      if date_targets.include?(column) && line[column].to_s.length > 0
    #        ohash[column] = Time.parse(line[column].to_s).strftime("%Y-%m-%d %H:%M:%S")
    #      end
    #
    #    end
    #    array2.push ohash
    #  end
    #
    #  #empty_hash.keys.each do |key|
    #  #end
    #
    #  puts "#### ignored #{allele_name_counter} allele_names!".red if allele_name_counter > 0
    #
    #  # p empty_hash
    #
    #  array3 = []
    #  array2.each do |line|
    #    empty_hash.keys.each do |key|
    #      line.delete(key) if ! empty_hash[key]
    #    end
    #
    #    array3.push line
    #
    #    #pp line
    #    #pp array3
    #    #exit
    #  end
    #
    #  #['a', 'b', 'c'].collect {|x| "'#{x}'"}
    #
    #  array3 = array3.sort do |a1, a2|
    #    a1['id'].to_i <=> a2['id'].to_i
    #  end
    #
    #  CSV.open(filename.gsub(/\.csv/, '-regular.csv'), "wb") do |csv|
    #    #csv << array3.first.keys.collect {|key| "\"#{key}\""}
    #    csv << array3.first.keys
    #    array3.each do |hash|
    #      #csv << hash.values.collect {|value| "\"#{value}\""}
    #      csv << hash.values
    #    end
    #  end
    #end
    #
    def self.download_and_normalize filename, solr
      #home = Dir.home
      #filename = "#{home}/Desktop/solr-old-all.csv"
      #solr = "http://localhost:8985/solr"
      command = "curl -o #{filename} '#{solr}/allele/select/?q=*:*&version=2.2&start=0&rows=1000000&indent=on&wt=csv'"
      puts command.blue
      output = `#{command}`
      puts output if output

      #exit

      array = []
      counter = 0
      headers = nil
      CSV.foreach(filename, :headers => true) do |row|
        headers = row.headers if headers.nil?
        hash = Hash[row.headers[0..-1].zip(row.fields[0..-1])]
        array.push hash
        counter += 1
      end

      if array.size == 0
        puts "#### empty '#{filename}'!".red
        exit
      end

      split_targets = %W{project_ids project_statuses project_pipelines vector_project_statuses vector_project_ids}
      humanize_targets = %W{project_statuses vector_project_statuses status}
      humanize_targets2 = %W{status}
      date_targets = %W{effective_date}

      headers = headers.sort

      array2 = []
      empty_hash = {}
      allele_name_counter = 0
      array.each do |line|

        if line['type'] == 'allele'
          if line['allele_name'].to_s =~ /\<sup\>\<\/sup\>/
            line['allele_name'] = nil
            allele_name_counter += 1
          end
        end

        if line['type'] == 'mi_attempt'
          if ! MiAttempt.find(line['id']).report_to_public
            puts "#### mi_attempt ignoring #{line['id']}".red
            next
          end

          line['order_from_names'] = line['order_from_names'].to_s.split(',')
          line['order_from_urls'] = line['order_from_urls'].to_s.split(',')

          line['order_from_names'] = line['order_from_names'].sort.uniq
          line['order_from_urls'] = line['order_from_urls'].sort.uniq
        end

        ohash = ActiveSupport::OrderedHash.new
        headers.each do |column|
          ohash[column] = line[column]
          empty_hash[column] ||= false
          target = line[column].to_s
          target = target.strip || target
          empty_hash[column] = empty_hash[column] || target.to_s.length > 0

          if split_targets.include? column
            split = line[column].to_s.split ','

            ohash[column] = split.sort.join '|'

            if humanize_targets.include? column
              ohash[column] = ohash[column].to_s.gsub(' -', '').gsub(' ', '_').gsub('-', '').downcase
            end
          end

          if humanize_targets2.include? column
            ohash[column] = ohash[column].to_s.gsub(' -', '').gsub(' ', '_').gsub('-', '').downcase
          end

          if date_targets.include?(column) && line[column].to_s.length > 0
            ohash[column] = Time.parse(line[column].to_s).strftime("%Y-%m-%d %H:%M:%S")
          end

        end
        array2.push ohash
      end

      puts "#### ignored #{allele_name_counter} allele_names!".red if allele_name_counter > 0

      array3 = []
      array2.each do |line|
        empty_hash.keys.each do |key|
          line.delete(key) if ! empty_hash[key]
        end

        array3.push line
      end

      array3 = array3.sort do |a1, a2|
        a1['id'].to_i <=> a2['id'].to_i
      end

      CSV.open(filename.gsub(/\.csv/, '-regular.csv'), "wb") do |csv|
      #CSV.open(filename, "wb") do |csv|
        csv << array3.first.keys
        array3.each do |hash|
          csv << hash.values
        end
      end

      #`mv #{filename.gsub(/\.csv/, '-regular.csv')} #{filename}`
      #puts "mv #{filename.gsub(/\.csv/, '-regular.csv')} #{filename}".blue

     # FileUtils.mv(filename.gsub(/\.csv/, '-regular.csv'), filename)
    end
  end

end
