#!/usr/bin/env ruby

require 'pp'
require 'color'

class PhenotypeAttemptsTest
  SOLR_UPDATE = YAML.load_file("#{Rails.root}/config/solr_update.yml")

  class CompareSolr

    def initialize
      @solr_current = Rails.env
      @solr_alt = Rails.env.production? ? 'staging' : 'production'
      @frame = {
        'development' => {
          :statuses => {
            :current_pa_status => {},
            :best_status_pa_cre_ex_not_required => {},
            :best_status_pa_cre_ex_required => {}
          }
        },
        'staging' => {
          :statuses => {
            :current_pa_status => {},
            :best_status_pa_cre_ex_not_required => {},
            :best_status_pa_cre_ex_required => {}
          }
        },
        'production' => {
          :statuses => {
            :current_pa_status => {},
            :best_status_pa_cre_ex_not_required => {},
            :best_status_pa_cre_ex_required => {}
          }
        },
        :compare => {:diffs => {}}
      }
    end

    def dump_pa id
      phenotype_attempt = PhenotypeAttempt.find_by_id id
      if phenotype_attempt && (phenotype_attempt.has_status? :cec and ! phenotype_attempt.has_status? :abt and phenotype_attempt.allele_id > 0 and phenotype_attempt.report_to_public)
        puts "#### phenotype_attempt OK!".green
      else
        puts "#### phenotype_attempt invalid!".red
      end

      pp phenotype_attempt.attributes
    end

    def count_solr target
      #url = "#{SOLR_UPDATE[Rails.env]['index_proxy']['allele']}/select?q=type:phenotype_attempt&version=2.2&start=0&rows=1000000&indent=on"
      #puts url
      proxy = SolrBulk::Proxy.new(SOLR_UPDATE[target]['index_proxy']['allele'])
      result = proxy.search_count({:q => 'type:phenotype_attempt'})
      # pp result

      @frame[target][:count] = result
      @frame[target][:ids] = []

      docs = proxy.search({:q => 'type:phenotype_attempt'}, 100000)

      docs.each do |doc|
        @frame[target][:ids].push doc['id']
        @frame[target][:statuses][:current_pa_status][doc['current_pa_status']] ||= 0
        @frame[target][:statuses][:current_pa_status][doc['current_pa_status']] += 1

        if ! doc['best_status_pa_cre_ex_not_required'].empty?
          @frame[target][:statuses][:best_status_pa_cre_ex_not_required][doc['best_status_pa_cre_ex_not_required']] ||= 0
          @frame[target][:statuses][:best_status_pa_cre_ex_not_required][doc['best_status_pa_cre_ex_not_required']] += 1
          #puts "#### best_status_pa_cre_ex_not_required:"
          #pp doc
         # dump_pa doc['id']
        end

        if ! doc['best_status_pa_cre_ex_required'].empty?
          @frame[target][:statuses][:best_status_pa_cre_ex_required][doc['best_status_pa_cre_ex_required']] ||= 0
          @frame[target][:statuses][:best_status_pa_cre_ex_required][doc['best_status_pa_cre_ex_required']] += 1
        end
      end

      @frame[target][:statuses][:current_pa_status] = Hash[@frame[target][:statuses][:current_pa_status].sort]
      @frame[target][:statuses][:best_status_pa_cre_ex_not_required] = Hash[@frame[target][:statuses][:best_status_pa_cre_ex_not_required].sort]
      @frame[target][:statuses][:best_status_pa_cre_ex_required] = Hash[@frame[target][:statuses][:best_status_pa_cre_ex_required].sort]

      @frame[target][:ids] = @frame[target][:ids].sort
    end

    def summary
      # get counts from solr & db

      count_solr @solr_current
      count_solr @solr_alt
      # count_db

      # puts "DB COUNT: #{count_db} - SOLR COUNT: #{count_solr}"

      # pp @frame

#     :best_status_pa_cre_ex_not_required=>{"Cre Excision Complete"=>1},

      message = ''

      if @frame[@solr_current][:ids].size > @frame[@solr_alt][:ids].size
        diff = @frame[@solr_current][:ids] - @frame[@solr_alt][:ids]
        message = "missing from #{@solr_alt}"
      else
        diff = @frame[@solr_alt][:ids] - @frame[@solr_current][:ids]
        message = "missing from current (#{@solr_current})"
      end

      @frame[@solr_alt].delete(:ids)
      @frame[@solr_current].delete(:ids)

      @frame[:compare][:diffs]['ids'] = diff
      @frame[:compare][:diffs]['message'] = message

      newdiff = []
      diff.each do |id|
        phenotype_attempt = PhenotypeAttempt.find_by_id id
        if ! phenotype_attempt || (phenotype_attempt.has_status? :cec and ! phenotype_attempt.has_status? :abt and phenotype_attempt.allele_id > 0 and phenotype_attempt.report_to_public)
          newdiff.push id
        end
      end

      @frame[:compare][:diffs]['ids'] = newdiff
      @frame[:compare][:diffs]['message'] = '' if newdiff.empty?

      #pp @frame

      puts "Comparing #{@solr_current} with #{@solr_alt}".blue
      failed = false

      if @frame[@solr_current][:count].to_i != @frame[@solr_alt][:count].to_i
        failed = true
        puts "counts wrong (#{@frame[@solr_current][:count].to_i}/#{@frame[@solr_alt][:count].to_i})".red
      end

      if @frame[:compare][:diffs]['ids'].size != 0 || @frame[:compare][:diffs]['ids'].size != 0
        failed = true
        puts "found diffs: (#{@frame[:compare][:diffs]['ids'].size}/#{@frame[:compare][:diffs]['ids'].size})".red
      end

      #puts "status checks..."

      statuses = [:current_pa_status, :best_status_pa_cre_ex_not_required, :best_status_pa_cre_ex_required]
      statuses.each do |status|
        @frame[@solr_current][:statuses][status].keys.each do |status_name|
          if @frame[@solr_current][:statuses][status][status_name].to_i != @frame[@solr_alt][:statuses][status][status_name].to_i
            failed = true
            puts "#{status_name}: (#{@frame[@solr_alt][:statuses][status][status_name].to_i}/#{@frame[@solr_current][:statuses][status][status_name].to_i})".red
          end
        end
      end

      #pp @frame

      if failed
        puts "failed!".red
      else
        puts "OK!".green
      end

      @frame
    end
  end

  class CompareBase
    def initialize
      @count = 0
      @failed_count = 0
    end

    def prologue
    end

    def epilogue
    end

    def get_old object
    end

    def get_new object
    end

    def compare old, new
    end

    def run
      prologue

      PhenotypeAttempt.all.each do |phenotype_attempt|
        if phenotype_attempt.has_status? :cec and ! phenotype_attempt.has_status? :abt and phenotype_attempt.allele_id > 0 and phenotype_attempt.report_to_public
          old = get_old phenotype_attempt
          new = get_new phenotype_attempt

          compare(old, new)
        end
      end

      epilogue
    end
  end

  def initialize(enabler = nil)
    @count = 0
    @failed_count = 0

    @enabler = enabler || {
      'test_phenotype_attempt_allele_type' => true,
      'test_phenotype_attempt_allele_name' => true,
      'test_phenotype_attempt_order_from_names' => true,
      'test_phenotype_attempt_order_from_urls' => true,
      'test_phenotype_attempt_best_status_pa_cre' => true,
      'test_solr_phenotype_attempts' => true
    }
  end

  def self.summary
    PhenotypeAttemptsTest::CompareSolr.new.summary
  end

  def phenotype_attempt_allele_type phenotype_attempt
    allele_type = ''
    if phenotype_attempt.mouse_allele_symbol.nil?
      allele_type = phenotype_attempt.mi_attempt.allele_symbol
    else
      allele_type = phenotype_attempt.mouse_allele_symbol
    end

    allele_type = '' if allele_type.nil?

    target = allele_type[/\>(.+)?\(/, 1]
    target = target ? " (#{target})" : ''

    "Cre-excised deletion#{target}"
  end

  def test_phenotype_attempt_allele_type
    @count = 0
    @failed_count = 0

    PhenotypeAttempt.all.each do |phenotype_attempt|
      if phenotype_attempt.has_status? :cec and ! phenotype_attempt.has_status? :abt and phenotype_attempt.allele_id > 0 and phenotype_attempt.report_to_public
        old = phenotype_attempt_allele_type phenotype_attempt

        rows = ActiveRecord::Base.connection.execute("select * from solr_get_pa_allele_type(#{phenotype_attempt.id})")

        count = 0
        new = ''
        rows.each do |row|
          new = row['solr_get_pa_allele_type']
          count += 1
        end

        raise "#### invalid count detected!".red if count != 1

        if old != new
          puts "#### error: #{phenotype_attempt.id}: (#{old}/#{new})".red
          @failed_count += 1
        end

        @count += 1
      end
    end
  end

  def test_phenotype_attempt_allele_name
    @count = 0
    @failed_count = 0

    PhenotypeAttempt.all.each do |phenotype_attempt|
      if phenotype_attempt.has_status? :cec and ! phenotype_attempt.has_status? :abt and phenotype_attempt.allele_id > 0 and phenotype_attempt.report_to_public
        old = phenotype_attempt.allele_symbol

        rows = ActiveRecord::Base.connection.execute("select * from solr_get_pa_allele_name(#{phenotype_attempt.id})")

        count = 0
        new = ''
        rows.each do |row|
          new = row['solr_get_pa_allele_name']
          count += 1
        end

        raise "#### invalid count detected!".red if count != 1

        if old != new
          puts "#### error: #{phenotype_attempt.id}: (#{old}/#{new})".red
          @failed_count += 1
        end

        @count += 1
      end
    end
  end

  def test_phenotype_attempt_order_from_names
    @count = 0
    @failed_count = 0

    PhenotypeAttempt.all.each do |phenotype_attempt|
      if phenotype_attempt.has_status? :cec and ! phenotype_attempt.has_status? :abt and phenotype_attempt.allele_id > 0 and phenotype_attempt.report_to_public
        solr_doc = {}
        SolrUpdate::DocFactory.set_order_from_details(phenotype_attempt, solr_doc)
        old = solr_doc

        next if old.empty? || old['order_from_names'].empty?

        old = old['order_from_names']

        rows = ActiveRecord::Base.connection.execute("select * from solr_get_pa_order_from_names(#{phenotype_attempt.id})")

        count = 0
        new = ''
        rows.each do |row|
          new = row['solr_get_pa_order_from_names'].split ';'
          count += 1
        end

        raise "#### invalid count detected!".red if count != 1

        old = old.sort
        new = new.sort

        if old.size != new.size
          puts "#### size error: #{phenotype_attempt.id}: (#{old}/#{new})".red
          @failed_count += 1
        else
          i = 0
          failed = false
          old.each do |name|
            if old[i] != new[i]
              puts "#### error: #{phenotype_attempt.id}: (#{old[i]}/#{new[i]})".red
              failed = true
            end
            i += 1
          end
          @failed_count += 1 if failed
        end

        @count += 1
      end
    end
  end

  def test_phenotype_attempt_order_from_urls
    @count = 0
    @failed_count = 0

    PhenotypeAttempt.all.each do |phenotype_attempt|
      if phenotype_attempt.has_status? :cec and ! phenotype_attempt.has_status? :abt and phenotype_attempt.allele_id > 0 and phenotype_attempt.report_to_public
        solr_doc = {}
        SolrUpdate::DocFactory.set_order_from_details(phenotype_attempt, solr_doc)
        old = solr_doc

        next if old.empty? || old['order_from_urls'].empty?

        old = old['order_from_urls']

        rows = ActiveRecord::Base.connection.execute("select * from solr_get_pa_get_order_from_urls(#{phenotype_attempt.id})")

        count = 0
        new = ''
        rows.each do |row|
          new = row['solr_get_pa_get_order_from_urls'].split ';'
          count += 1
        end

        raise "#### invalid count detected!".red if count != 1

        old = old.sort
        new = new.sort

        if old.size != new.size
          puts "#### size error: #{phenotype_attempt.id}: (#{old}/#{new})".red
          @failed_count += 1
        else
          i = 0
          failed = false
          old.each do |name|
            if old[i] != new[i]
              puts "#### error: #{phenotype_attempt.id}: (#{old[i]}/#{new[i]})".red
              failed = true
            end
            i += 1
          end
          @failed_count += 1 if failed
        end

        @count += 1
      end
    end
  end

  def test_phenotype_attempt_best_status_pa_cre cre_excision_required
    @count = 0
    @failed_count = 0

    PhenotypeAttempt.all.each do |phenotype_attempt|
      if phenotype_attempt.has_status? :cec and ! phenotype_attempt.has_status? :abt and phenotype_attempt.allele_id > 0 and phenotype_attempt.report_to_public
        old = nil
        old = phenotype_attempt.status.name if cre_excision_required && phenotype_attempt.cre_excision_required
        old = phenotype_attempt.status.name if ! cre_excision_required && ! phenotype_attempt.cre_excision_required

        next if ! old

        rows = ActiveRecord::Base.connection.execute("select * from solr_get_best_status_pa_cre(#{phenotype_attempt.id}, #{cre_excision_required})")

        count = 0
        new = ''
        rows.each do |row|
          new = row['solr_get_best_status_pa_cre']
          count += 1
        end

        raise "#### invalid count detected!".red if count != 1

        if old != new
          puts "#### error: #{phenotype_attempt.id}: (#{old}/#{new})".red
          @failed_count += 1
        end

        @count += 1
      end
    end
  end

  def test_solr_phenotype_attempts
    @count = 0
    @failed_count = 0
    count = 0

    hash = {}

    attempts = ActiveRecord::Base.connection.execute("select * from solr_phenotype_attempts")

    attempts.each do |attempt|
      attempt['order_from_names'] = attempt['order_from_names'].to_s.split(';')
      attempt['order_from_urls'] = attempt['order_from_urls'].to_s.split(';')
      attempt['project_ids'] = attempt['project_ids'].to_s.split(';')
      hash[attempt['id'].to_i] = attempt.clone
      count += 1
    end

    PhenotypeAttempt.order(:id).each do |pa|
      if pa.has_status? :cec and ! pa.has_status? :abt and pa.allele_id > 0 and pa.report_to_public
        failed = false

        if pa.has_status? :cec and ! pa.has_status? :abt and pa.allele_id > 0 and pa.report_to_public
          docs = SolrUpdate::DocFactory.create_for_phenotype_attempt(pa)
          doc = docs.first
          next if ! doc

          if ! hash.has_key?(doc['id'])
            puts "#### missing key: (#{doc['id']})".red
            failed = true
          end

          if doc.keys.size != hash[doc['id']].keys.size
            puts "#### key count error: (#{doc.keys.size}/#{hash[doc['id']].keys.size})".red
            failed = true
          end

          splits = %W{order_from_names order_from_urls project_ids}

          old = doc
          new = hash[doc['id']]

          splits.each do |split|
            if old[split].size != new[split].size
              puts "#### #{doc['id']}: split count error: '#{split}' (#{old[split].size}/#{new[split].size})".red
              failed = true
            end

            old[split] = old[split].sort
            new[split] = new[split].sort
            i = 0
            old[split].each do |item|
              if item != new[split][i]
                puts "#### #{doc['id']}: split compare error: '#{split}' (#{item}/#{new[split][i]})".red
                failed = true
              end
              i += 1
            end
          end

          old.keys.each do |key|
            next if splits.include?(key)
            if old[key].to_s != new[key].to_s
              puts "#### #{doc['id']}: compare error: '#{key}' (#{old[key]}/#{new[key]})".red
              failed = true
            end
          end

          @count += 1
          @failed_count += 1 if failed
        end
      end
    end

    puts "#### count error: (#{count}/#{@count})".red if count != @count
  end

  def _run(routine)
    self.send(routine)
    puts "#### done #{routine}: (#{@failed_count}/#{@count})".red if @failed_count > 0
    puts "#### done #{routine}: (#{@count})".green if @failed_count == 0
  end

  def _run2(routine, param)
    self.send(routine, param)
    puts "#### done #{routine}(#{param}): (#{@failed_count}/#{@count})".red if @failed_count > 0
    puts "#### done #{routine}(#{param}): (#{@count})".green if @failed_count == 0
  end

  def run
    puts "#### starting phenotype_attempts...".blue

    sql = 'CREATE temp table solr_get_pa_order_from_names_tmp ( phenotype_attempt_id int, name text ) ;'
    sql += 'CREATE temp table solr_get_pa_get_order_from_urls_tmp ( phenotype_attempt_id int, url text ) ;'

    ActiveRecord::Base.connection.execute(sql)

    _run('test_solr_phenotype_attempts') if @enabler['test_solr_phenotype_attempts']

    _run('test_phenotype_attempt_allele_type') if @enabler['test_phenotype_attempt_allele_type']
    _run('test_phenotype_attempt_allele_name') if @enabler['test_phenotype_attempt_allele_name']
    _run('test_phenotype_attempt_order_from_names') if @enabler['test_phenotype_attempt_order_from_names']
    _run('test_phenotype_attempt_order_from_urls') if @enabler['test_phenotype_attempt_order_from_urls']

    _run2('test_phenotype_attempt_best_status_pa_cre', true) if @enabler['test_phenotype_attempt_best_status_pa_cre']
    _run2('test_phenotype_attempt_best_status_pa_cre', false) if @enabler['test_phenotype_attempt_best_status_pa_cre']
  end
end

PhenotypeAttemptsTest.new.run if File.basename($0) !~ /rake/

#puts "#### File.basename($0): #{File.basename($0)}"
