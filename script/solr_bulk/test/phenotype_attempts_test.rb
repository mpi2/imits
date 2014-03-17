#!/usr/bin/env ruby

require 'pp'
require 'color'

class PhenotypeAttemptsTest
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
    sql = 'CREATE temp table solr_get_pa_order_from_names_tmp ( phenotype_attempt_id int, name text ) ;'
    sql += 'CREATE temp table solr_get_pa_get_order_from_urls_tmp ( phenotype_attempt_id int, url text ) ;'

    ActiveRecord::Base.connection.execute(sql)

    _run('test_phenotype_attempt_allele_type') if @enabler['test_phenotype_attempt_allele_type']
    _run('test_phenotype_attempt_allele_name') if @enabler['test_phenotype_attempt_allele_name']
    _run('test_phenotype_attempt_order_from_names') if @enabler['test_phenotype_attempt_order_from_names']
    _run('test_phenotype_attempt_order_from_urls') if @enabler['test_phenotype_attempt_order_from_urls']

    #if enabler['test_phenotype_attempt_best_status_pa_cre']
    #  test_phenotype_attempt_best_status_pa_cre false
    #  puts "#### done test_phenotype_attempt_best_status_pa_cre: (#{@failed_count}/#{@count})".red if @failed_count > 0
    #  puts "#### done test_phenotype_attempt_best_status_pa_cre: (#{@count})".green if @failed_count == 0
    #
    #  test_phenotype_attempt_best_status_pa_cre true
    #  puts "#### done test_phenotype_attempt_best_status_pa_cre: (#{@failed_count}/#{@count})".red if @failed_count > 0
    #  puts "#### done test_phenotype_attempt_best_status_pa_cre: (#{@count})".green if @failed_count == 0
    #end

    _run2('test_phenotype_attempt_best_status_pa_cre', true) if @enabler['test_phenotype_attempt_best_status_pa_cre']
    _run2('test_phenotype_attempt_best_status_pa_cre', false) if @enabler['test_phenotype_attempt_best_status_pa_cre']

    _run('test_solr_phenotype_attempts') if @enabler['test_solr_phenotype_attempts']
  end
end

PhenotypeAttemptsTest.new.run if File.basename($0) !~ /rake/

#puts "#### File.basename($0): #{File.basename($0)}"
