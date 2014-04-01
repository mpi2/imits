
require 'pp'
require 'fileutils'

module SolrBulk
  class Load
    SOLR_BULK = YAML.load_file("#{Rails.root}/config/solr_bulk.yml")
    SOLR_UPDATE = YAML.load_file("#{Rails.root}/config/solr_update.yml")

    PHENOTYPE_ATTEMPTS_SQL = SOLR_BULK['phenotype_attempts_sql']
    MI_ATTEMPTS_SQL = SOLR_BULK['mi_attempts_sql']
    ALLELE_SQL = SOLR_BULK['allele_sql']
    GENES_SQL = SOLR_BULK['genes_sql']

    def self.alleles(id = nil)
      list = []
      counter = 0
      splits = %W{order_from_names order_from_urls project_ids project_statuses project_pipelines vector_project_ids vector_project_statuses}

      sql = "select * from solr_alleles"
      sql = "select * from solr_alleles where id = #{id}" if id && id.to_i > 0

      alleles = ActiveRecord::Base.connection.execute(sql)

      alleles.each do |allele|

        splits.each do |split|
          allele[split] = allele[split].try(:split, ';').try(:uniq)
        end

        #allele['order_from_names'] = allele['order_from_names'].try(:split, ';').try(:uniq)
        #allele['order_from_urls'] = allele['order_from_urls'].try(:split, ';').try(:uniq)

        item = {'add' => {'doc' => allele }}
        list.push item.to_json
        counter += 1
      end

      puts "#### #{counter} alleles!"

      list
    end

    def self.genes(id = nil)
      list = []
      counter = 0

      sql = "select * from solr_genes"
      sql = "select * from solr_genes where id = #{id}" if id && id.to_i > 0

      items = ActiveRecord::Base.connection.execute(sql)

      items.each do |item|
        splits = %W{project_ids project_statuses project_pipelines vector_project_statuses vector_project_ids}
        splits.each do |target|
          item[target] = '' if ! item[target]
          item[target] = item[target].split(';').uniq if item[target]
        end

        item = {'add' => {'doc' => item }}
        list.push item.to_json
        counter += 1
      end

      puts "#### #{counter} genes!"

      list
    end

    def self.mi_attempts(id = nil)
      list = []
      counter = 0

      sql = "select * from solr_mi_attempts"
      sql = "select * from solr_mi_attempts where id = #{id}" if id && id.to_i > 0

      attempts = ActiveRecord::Base.connection.execute(sql)

      attempts.each do |mi_attempt|

        mi_attempt['order_from_names'] = mi_attempt['order_from_names'].to_s.split(';').uniq
        mi_attempt['order_from_urls'] = mi_attempt['order_from_urls'].to_s.split(';').uniq
        mi_attempt['project_ids'] = mi_attempt['project_ids'].to_s.split(';').uniq

        item = {'add' => {'doc' => mi_attempt }}
        list.push item.to_json
        counter += 1
      end

      puts "#### #{counter} mi_attempts!"

      list
    end

    def self.phenotype_attempts(id = nil)
      list = []
      counter = 0

      sql = "select * from solr_phenotype_attempts"
      sql = "select * from solr_phenotype_attempts where id = #{id}" if id && id.to_i > 0

      attempts = ActiveRecord::Base.connection.execute(sql)

      attempts.each do |attempt|
        attempt['order_from_names'] = attempt['order_from_names'].to_s.split(';').uniq
        attempt['order_from_urls'] = attempt['order_from_urls'].to_s.split(';').uniq
        attempt['project_ids'] = attempt['project_ids'].to_s.split(';').uniq

        item = {'add' => {'doc' => attempt }}
        list.push item.to_json
        counter += 1
      end

      puts "#### #{counter} phenotype_attempts!"

      list
    end

    # http://wiki.apache.org/solr/UpdateJSON

    def self.run(targets)
      puts "#### loading index: '#{SOLR_UPDATE[Rails.env]['index_proxy']['allele']}'"

      delete targets  # remove docs from the index based on targets

      list = []

      list += phenotype_attempts if targets.empty? || targets.include?('phenotype_attempts') || targets.include?('partial') || targets.include?('all')
      list += mi_attempts if targets.empty? || targets.include?('mi_attempts') || targets.include?('partial') || targets.include?('all')
      list += alleles if targets.empty? || targets.include?('alleles') || targets.include?('all')
      list += genes if targets.empty? || targets.include?('genes') || targets.include?('all')

      #puts "#### list.size: #{list.size}"

      sublist = list.each_slice(1000).to_a

      sublist.each { |item| command item.join }

      commit
    end

    def self.run_single(target, id)
      puts "#### loading index: '#{SOLR_UPDATE[Rails.env]['index_proxy']['allele']}'"

      raise "#### target cannot be empty!" if target.empty?
      raise "#### id cannot be empty!" if ! id || id.to_i < 1

      #delete targets  # remove docs from the index based on targets

      command({'delete' => {'query' => "type:#{target} id:#{id}"}}.to_json)

      list = []

      list += phenotype_attempts(id) if target == 'phenotype_attempt'
      list += mi_attempts(id) if target == 'mi_attempt'
      list += alleles(id) if target == 'allele'
      list += genes(id) if target == 'gene'

      sublist = list.each_slice(1000).to_a

      sublist.each { |item| command item.join }

      commit
    end

    def self.delete targets
      if targets.include?('all')
        command({'delete' => {'query' => '*:*'}}.to_json)
        return
      end

      if targets.include?('partial')
        %W{phenotype_attempts mi_attempts}.each do |t|
          puts "#### deleting #{t}"
          command({'delete' => {'query' => "type:#{t.singularize}"}}.to_json)
        end
        return
      end

      targets.each do |t|
        puts "#### deleting #{t}"
        command({'delete' => {'query' => "type:#{t.singularize}"}}.to_json)
      end
    end

    def self.commit
      command({'commit' => {}}.to_json)
    end

    def self.command(json)
      #puts json
      #exit
      proxy = SolrBulk::Proxy.new(SOLR_UPDATE[Rails.env]['index_proxy']['allele'])
      proxy.update(json)
    end
  end

end
