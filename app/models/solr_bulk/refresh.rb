
require 'pp'
require 'fileutils'

module SolrBulk

  class Refresh

    SOLR_BULK = YAML.load_file("#{Rails.root}/config/solr_bulk.yml")
    DIST_CENTRE_URLS = YAML.load_file("#{Rails.root}/config/dist_centre_urls.yml")

    MI_ATTEMPTS_SQL = SOLR_BULK['mi_attempts_sql']
    PHENOTYPE_ATTEMPTS_SQL = SOLR_BULK['phenotype_attempts_sql']
    ALLELE_SQL = SOLR_BULK['allele_sql']
    GENES_SQL = SOLR_BULK['genes_sql']
    TARGETS = SOLR_BULK['targets']

    def self.prologue
    end

    def self.epilogue
    end

    def self.alleles
      list = []
      counter = 0

      alleles = ActiveRecord::Base.connection.execute(ALLELE_SQL)

      alleles.each do |allele|

        allele['order_from_names'] = allele['order_from_names'].try(:split, ';').try(:uniq)
        allele['order_from_urls'] = allele['order_from_urls'].try(:split, ';').try(:uniq)

        item = {'add' => {'doc' => allele }}
        list.push item.to_json
        counter += 1
      end

      puts "#### #{counter} alleles!"

      list
    end

    def self.genes
      list = []
      counter = 0

      items = ActiveRecord::Base.connection.execute(GENES_SQL)

      items.each do |item|

        ## TODO: use array
        #targets = %W{project_ids project_statuses project_pipelines vector_project_statuses vector_project_ids}
        #targets.each do |target|
        #  item[target] = '' if ! item[target]
        #  item[target] = item[target].split(';').uniq if item[target]
        #end

        item['project_ids'] = '' if ! item['project_ids']
        item['project_statuses'] = '' if ! item['project_statuses']
        item['project_pipelines'] = '' if ! item['project_pipelines']
        item['vector_project_statuses'] = '' if ! item['vector_project_statuses']
        item['vector_project_ids'] = '' if ! item['vector_project_ids']

        item['project_ids'] = item['project_ids'].split(';') if item['project_ids']
        item['project_statuses'] = item['project_statuses'].split(';') if item['project_statuses']
        item['project_pipelines'] = item['project_pipelines'].split(';') if item['project_pipelines']
        item['vector_project_statuses'] = item['vector_project_statuses'].split(';') if item['vector_project_statuses']

        #if item['id'].to_i == 22004
        #  puts "#### item['vector_project_ids']: #{item['vector_project_ids']}"
        #end

        item['vector_project_ids'] = item['vector_project_ids'].split(';') if item['vector_project_ids']

        #if item['id'].to_i == 22004
        #  puts "#### item['vector_project_ids']: #{item['vector_project_ids']}"
        #end

        #item['status'] = item['status'].titleize if item['status']

        item = {'add' => {'doc' => item }}
        list.push item.to_json
        counter += 1
      end

      puts "#### #{counter} genes!"

      list
    end

    def self.phenotype_attempts
      list = []
      counter = 0

      attempts = ActiveRecord::Base.connection.execute(PHENOTYPE_ATTEMPTS_SQL)

      attempts.each do |attempt|
        attempt['order_from_names'] = attempt['order_from_names'].split(';').uniq
        attempt['order_from_urls'] = attempt['order_from_urls'].split(';').uniq

        item = {'add' => {'doc' => attempt }}
        list.push item.to_json
        counter += 1
      end

      puts "#### #{counter} phenotype_attempts!"

      list
    end

    def self.mi_attempts
      list = []
      counter = 0

      attempts = ActiveRecord::Base.connection.execute(MI_ATTEMPTS_SQL)

      attempts.each do |mi_attempt|

        mi_attempt['order_from_names'] = mi_attempt['order_from_names'].split(';').uniq
        mi_attempt['order_from_urls'] = mi_attempt['order_from_urls'].split(';').uniq

        item = {'add' => {'doc' => mi_attempt }}
        list.push item.to_json
        counter += 1
      end

      puts "#### #{counter} mi_attempts!"

      list
    end

    # http://wiki.apache.org/solr/UpdateJSON

    def self.run
      prologue

      puts "#### loading index: '#{SOLR_BULK['compare'][:index_new]}'"

      delete

      list = []

      list += mi_attempts if TARGETS.include? 'mi_attempt'
      list += phenotype_attempts if TARGETS.include? 'phenotype_attempt'
      list += genes if TARGETS.include? 'gene'
      list += alleles if TARGETS.include? 'allele'

      new_list2 = list.each_slice(1000).to_a

      new_list2.each do |thing|
        load thing.join
      end

      commit

      epilogue
    end

    def self.delete
      load({'delete' => {'query' => '*:*'}}.to_json)
    end

    def self.commit
      load({'commit' => {}}.to_json)
    end

    def self.load(json)
      proxy = SolrBulk::Proxy.new(SOLR_BULK['compare'][:index_new])
      proxy.update(json)
    end
  end

end
