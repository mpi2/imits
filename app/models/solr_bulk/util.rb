
require 'pp'
require 'fileutils'

module SolrBulk
  module Util
    LEGAL_EXTENSIONS = ['.csv']
    TARGETS = []
    TYPES = %W{gene phenotype_attempt mi_attempt allele}

    def self.download_and_normalize filename, solr
      command = "curl -o #{filename} '#{solr}/select/?q=*:*&version=2.2&start=0&rows=1000000&indent=on&wt=csv'"
      puts command.blue
      output = `#{command}`
      puts output if output

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
        csv << array3.first.keys
        array3.each do |hash|
          csv << hash.values
        end
      end
    end

    SIMPLE = %W{
      id
      type
      product_type
      mgi_accession_id
      allele_type
      strain
      allele_name
      allele_image_url
      genbank_file_url
      order_from_url
      order_from_name
      allele_id
      status
      effective_date
      consortium
      production_centre
      best_status_pa_cre_ex_not_required
      best_status_pa_cre_ex_required
      current_pa_status
      simple_allele_image_url
      colony_name
      es_cell_name
      parent_mi_attempt_colony_name
      marker_symbol
      marker_type
    }

    MULTIVALUE = %W{
      project_ids
      project_statuses
      vector_project_ids
      vector_project_statuses
      project_pipelines
      order_from_urls
      order_from_names
    }

    #def normalize_array_generic targets, target
    #
    #  size = target[target.first].size
    #
    #  targets.each do |compare|
    #    puts "#### #{target['id']}: normalize_array error: (#{size}/#{target[compare].size})".red if size != target[compare].size
    #  end
    #
    #  order_from_names = []
    #  order_from_urls = []
    #  i = 0
    #  target['order_from_names'].to_a.each do |order_from_name|
    #    order_from_names.push({ 'index' => i, 'value' => order_from_name })
    #    i += 1
    #  end
    #
    #  order_from_names_arr = []
    #  order_from_names.sort.each do |item|
    #    order_from_names_arr.push(item['value'])
    #    order_from_urls.push(target['order_from_urls'][item['index']])
    #  end
    #
    #  target['project_ids'] = target['project_ids'].sort
    #  target['order_from_names'] = order_from_names_arr
    #  target['order_from_urls'] = order_from_urls
    #
    #  target
    #end

    def self.normalize_array_phenotype_attempt target
      if target['order_from_urls'].size != target['order_from_names'].size
        puts "#### #{target['id']}: normalize_array error: (#{target['order_from_names'].size}/#{target['order_from_urls'].size})".red
      end

      order_from_names = []
      order_from_urls = []
      i = 0
      target['order_from_names'].to_a.each do |order_from_name|
        order_from_names.push({ 'index' => i, 'value' => order_from_name })
        i += 1
      end

      order_from_names_arr = []
      order_from_names.sort.each do |item|
        order_from_names_arr.push(item['value'])
        order_from_urls.push(target['order_from_urls'][item['index']])
      end

      target['order_from_names'] = order_from_names_arr
      target['order_from_urls'] = order_from_urls

      target
    end

    def self.normalize_hash hash
      hash.keys.each do |key|
        line.delete(key) if ! hash[key]
      end

      if hash['type'] == 'phenotype_attempt'
        hash = normalize_array_phenotype_attempt hash
      end

      new_hash = ActiveSupport::OrderedHash.new

      hash.keys.sort.each do |key|
        new_hash[key] = hash[key]
      end

      new_hash
    end

    def self.compare_hashes old, new
      failed = false
      SIMPLE.each do |key|
        if old[key].to_s != new[key].to_s
          puts "#### #{old['id']} '#{key}': (#{old[key]}/#{new[key]})".red
          failed = true
        end
      end

      MULTIVALUE.each do |key|
        next if ! old[key] && ! new[key]
        i = 0
        old[key].each do |item|
          if item.to_s != new[key][i].to_s
            puts "#### #{old['id']}: compare_arrays error: (#{item}/#{new[split][i]})".red
            failed = true
          end
          i += 1
        end
      end

      return ! failed
    end

    def self.get_and_compare_phenotype_attempt(id)
      pa = PhenotypeAttempt.find_by_id id
      if ! pa
        puts "#### cannot find phenotype with id #{id}"
        return
      end

      old = nil
      new = nil

      if pa.has_status? :cec and ! pa.has_status? :abt and pa.allele_id > 0 and pa.report_to_public
        docs = SolrUpdate::DocFactory.create_for_phenotype_attempt(pa)
        doc = docs.first
        old = doc
        if ! doc
          puts "#### phenotype with id #{id} has no doc!"
          return
        end
      else
        puts "#### phenotype with id #{id} would not be procesed by the doc_factory"
        return
      end

      attempts = ActiveRecord::Base.connection.execute("select * from solr_phenotype_attempts where id = #{id}")

      test_count = 0
      attempts.each do |attempt|
        attempt['order_from_names'] = attempt['order_from_names'].to_s.split(';')
        attempt['order_from_urls'] = attempt['order_from_urls'].to_s.split(';')
        attempt['project_ids'] = attempt['project_ids'].to_s.split(';')
        new = attempt.clone
        test_count += 1
      end

      failed = false

      if test_count != 1
        puts "#### incorrect row rount: #{test_count}".red
        failed = true
      end

      old = normalize_hash old
      new = normalize_hash new

      old['project_ids'] = old['project_ids'].sort
      new['project_ids'] = new['project_ids'].sort

      pp old
      pp new

      failed = failed || ! compare_hashes(old, new)

      if failed
        puts "#### #{old['id']} failed".red
      else
        puts "#### #{old['id']} OK!".green
      end
    end

    def self.get_and_compare(target, id)
      if target == 'phenotype_attempt'
        get_and_compare_phenotype_attempt id
      end
    end
  end

end
