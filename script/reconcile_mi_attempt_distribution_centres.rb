#!/usr/bin/env ruby

##
# This class handles reconciling Mi Attempt Distribution Centres in Imits against the specified
# repository.
##
class ReconcileMiAttemptDistributionCentres

  require 'csv'

  attr_accessor :repository_name
  attr_accessor :reposcraper

  EMMA_REPO_NAME  = 'EMMA'
  KOMP_REPO_NAME  = 'KOMP Repo'
  MMRRC_REPO_NAME = 'MMRRC'

  ##
  # Any initialization before running checks
  ##
  def initialize( repo_name, check_reconciled, results_csv_filepath )

    @output_csv_filepath = nil

    # default to KOMP repo
    if ( repo_name.nil? )
      @repository_name = KOMP_REPO_NAME
      puts "Repository name passed in from rake task was nil, setting to default : #{@repository_name}"
    else
      @repository_name = repo_name
      puts "Repository name passed in from rake task : #{@repository_name}"
    end

    # default to not checking already reconciled mi distribution centre (NB params are strings)
    if check_reconciled.nil?
      @check_reconciled = false
      puts "Check reconciled flag passed in from rake task was nil, setting to default : #{@check_reconciled}"
    else
      if check_reconciled == 'true'
        @check_reconciled = true
        puts "This run WILL check already reconciled Mi Distribution Centres"
      else
        @check_reconciled = false
        puts "This run will NOT check already reconciled Mi Distribution Centres"
      end
    end

    if ( results_csv_filepath.nil? )
      puts "WARN: CSV results filepath passed in from rake task was nil, no results file will be created"
    else
      @output_csv_filepath = results_csv_filepath
      puts "CSV results filepath passed in from rake task : #{@output_csv_filepath}"
    end
  end

  ##
  # Reconcile all the Mi Attempt Distribution Centres for the selected repository
  ##
  def reconcile_all_mi_attempt_distribution_centres

    puts "Reconciling All Mi Attempt Distribution Centres"

    # selection of mi_distribution_centres depends on repository
    mi_distribution_centres = nil
    @reposcraper            = nil
    mi_results              = {}

    case @repository_name
    when EMMA_REPO_NAME
      mi_distribution_centres = self.class.select_mi_distribution_centres_by_distribution_network(@repository_name)
      @reposcraper            = ScraperEmmaRepository.new()
    when KOMP_REPO_NAME
      mi_distribution_centres = self.class.select_mi_distribution_centres_by_centre(@repository_name)
      @reposcraper            = ScraperKompRepository.new()
    when MMRRC_REPO_NAME
      mi_distribution_centres = self.class.select_mi_distribution_centres_by_distribution_network(@repository_name)
      @reposcraper            = ScraperMmrrcRepository.new()
    else
      puts "ERROR : repository name unrecognised when selecting mi_distribution_centres"
      return
    end # end case

    if mi_distribution_centres.nil?
      puts "No mi_distribution_centres found that meet criteria"
      return
    end

    puts "Number of mi attempt distribution centres selected = #{mi_distribution_centres.count()}"

    count_dcs_processed = 0
    count_dcs_skipped   = 0
    sleeptime_total     = 0

    mi_distribution_centres.each do |mi_distribution_centre|
      mi_attempt = mi_distribution_centre.colony.mi_attempt

      puts "---------------------------------------------"
      puts "Mi Attempt [num #{count_dcs_processed + count_dcs_skipped + 1}] : #{mi_attempt.id}"

      mi_plan          = mi_attempt.mi_plan
      consortium_name  = mi_plan.consortium.name
      marker_symbol    = mi_plan.gene.marker_symbol
      mi_dc_reconciled = mi_distribution_centre.reconciled

      puts "Status                      = #{mi_attempt.status.name}"
      puts "Consortium                  = #{consortium_name}"
      puts "Marker symbol               = #{marker_symbol}"

      # add to results hash, keyed on marker symbol and mi dc id
      unless mi_results.has_key?(marker_symbol)
        mi_results[marker_symbol] = {
          'marker_symbol'        => marker_symbol,
          'repository_name'      => @repository_name,
          'distribution_centres' => {}
        }

        if @repository_name == KOMP_REPO_NAME
          geneid = mi_plan.gene.komp_repo_geneid
          unless geneid.nil?
            mi_results[marker_symbol]['geneid'] = geneid
            puts "Komp Repo geneid in gene DB = #{geneid}"
          end
        end
      end

      mi_allele = self.class.get_allele_for_mi_distribution_centre(mi_distribution_centre)

      mi_results[marker_symbol]['distribution_centres'][mi_distribution_centre.id] = {
        'mi_dc_id'           => mi_distribution_centre.id,
        'mi_plan_id'         => mi_plan.id,
        'consortium'         => consortium_name,
        'current_reconciled' => mi_dc_reconciled,
        'allele'             => mi_allele,
        'action'             => 'none'
      }

      puts "Current reconciled          = #{mi_dc_reconciled}"

      unless @check_reconciled
        # only those not already reconciled
        puts "Check if already reconciled"
        if mi_dc_reconciled == "true"
          puts "This Mi Attempt Distribution Centre is already reconciled"
          count_dcs_skipped += 1
          puts "Skipping this Mi Attempt Distribution Centre"
          puts "---------------------------------------------"
          mi_results[marker_symbol]['distribution_centres'][mi_distribution_centre.id]['action'] = "skipped"
          next
        end
      end

      puts "Processing this Mi Attempt Distribution Centre"

      gene_repo_details = mi_distribution_centre.reconcile_with_repo( @repository_name, @reposcraper )

      mi_results[marker_symbol]['distribution_centres'][mi_distribution_centre.id]['action'] = "checked"

      if gene_repo_details.nil?
        puts "WARN: No gene details found for this gene at #{repository_name}"
      else
        mi_results[marker_symbol]['distribution_centres'][mi_distribution_centre.id]['repository_details'] = gene_repo_details
      end

      count_dcs_processed += 1
      puts "---------------------------------------------"

      # delay for random time in seconds before processing
      unless count_dcs_processed == 1
          sleeptime = rand(5)
          sleep(3 + sleeptime)
          sleeptime_total = sleeptime_total + sleeptime + 3
      end
    end

    puts '============================================================'
    puts "Total Mi Attempt Distribution Centres processed = #{count_dcs_processed}"
    puts "Total Mi Attempt Distribution Centres skipped   = #{count_dcs_skipped}"
    puts '============================================================'
    if @reposcraper
      puts "Total products 'mice' found         = #{@reposcraper.count_is_mice}"
      puts "Total products 'recovery' found     = #{@reposcraper.count_is_recovery}"
      puts "Total products 'germ plasm' found   = #{@reposcraper.count_is_germ_plasm}"
      puts "Total products 'embryos' found      = #{@reposcraper.count_is_embryos}"
      puts "Total alleles found                 = #{@reposcraper.count_unique_alleles_found}"
      puts "Total alleles found with products   = #{@reposcraper.count_unique_alleles_with_products}"
    end
    puts "Total time sleeping between scrapes = #{sleeptime_total} seconds"
    puts "------------------------------------------------------------"

    # write results to csv
    if @output_csv_filepath
      self.class.write_results_to_csv( mi_results, @output_csv_filepath )
    end

  end # reconcile_all_mi_attempt_distribution_centres

  ##
  # Reconcile the Mi Attempt Distribution Centres for the selected repository and a specified gene
  ##
  def reconcile_mi_attempt_distribution_centres_for_gene( marker_symbol )

    puts "Reconcile Mi Attempt Distribution Centres for gene : #{marker_symbol}"

    if ( marker_symbol.nil? )
      puts "ERROR: No marker symbol entered into method"
      return
    end

    # processing depends on repository
    case @repository_name
    when EMMA_REPO_NAME
      # _reconcile_emma_mi_attempt_distribution_centres_for_gene( marker_symbol )
      puts "NOT IMPLEMENTED YET"
    when KOMP_REPO_NAME
      _reconcile_komp_mi_attempt_distribution_centres_for_gene( marker_symbol )
    when MMRRC_REPO_NAME
      # _reconcile_mmrrc_mi_attempt_distribution_centres_for_gene( marker_symbol )
      puts "NOT IMPLEMENTED YET"
    else
      puts "ERROR : repository name unrecognised when reconciling Mi attempt"
      return
    end # end case

  end # reconcile_mi_attempt_distribution_centres_for_gene

  ##
  # Reconcile the Mi Attempt Distribution Centres for the KOMP repository and a specified gene
  ##
  def _reconcile_komp_mi_attempt_distribution_centres_for_gene( marker_symbol )

    puts "Reconcile KOMP repository Mi Attempt Distribution Centres for gene : #{marker_symbol}"

    # find gene for marker symbol
    gene = Gene.find_by_marker_symbol( marker_symbol )

    if ( gene.nil? )
      puts "ERROR : no gene located for marker symbol #{marker_symbol} in Imits"
      return
    end

    geneid = gene.komp_repo_geneid

    # create a new repository scraper instance
    puts "Creating Repo Scraper instance"
    if ( @reposcraper.nil? )
      @reposcraper = ScraperKompRepository.new()
    end

    # attempt to scrape the geneid from the KOMP website
    if ( geneid.nil? )
      geneid = @reposcraper.fetch_komp_geneid_for_marker_symbol( marker_symbol )
    end

    if ( geneid.nil? )
      puts "ERROR: geneid not found for #{marker_symbol}, cannot continue"
      return
    end
    puts "Found geneid = #{geneid} for #{marker_symbol}"

    # for mi_plans find mi_attempts
    # puts "Check Mi Plans for gene #{gene.marker_symbol}"
    mi_plans = gene.mi_plans
    mi_plans.each do |mi_plan|

      # puts "Check the Mi Attempts for Mi Plan id #{mi_plan.id}"
      mi_attempts = mi_plan.mi_attempts
      mi_attempts.each do |mi_attempt|

        # puts "Check Mi Attempt status for Mi Attempt id #{mi_attempt.id}"
        unless mi_attempt.status.name == 'Genotype confirmed'
            puts "Rejected Mi Attempt id #{mi_attempt.id}, in status #{mi_attempt.status.name}"
            next
        end

        # puts "Checking Distribution Centres for Mi Attempt id #{mi_attempt.id}"
        mi_distribution_centres = Colony::DistributionCentre.joins(:colony).where("colonies.mi_attempt_id = #{mi_attempt.id}")
        mi_distribution_centres.each do |mi_distribution_centre|

            puts "Reconcile Mi Plan id #{mi_plan.id} Mi Attempt id #{mi_attempt.id} at Distribution Centre #{mi_distribution_centre.id}"
            mi_distribution_centre.reconcile_with_repo( @repository_name, @reposcraper )
        end # distribution_centres
      end # mi_attempts
    end # mi_plans
  end # _reconcile_komp_mi_attempt_distribution_centres_for_gene

  private
    #####
    # select mi distribution centres by relation to a repository centre e.g. 'KOMP Repo'
    #####
    def self.select_mi_distribution_centres_by_centre(repository_name)
      repository_centre = Centre.find_by_name(repository_name)

      if repository_centre.nil?
        puts "ERROR : repository centre not found for #{repository_name}"
      else
        # N.B. can change filter in the Centre model to effect the Mi's selected for update
        mi_distribution_centres_unfiltered = repository_centre.mi_attempt_distribution_centres
        return self.filter_gtc_mi_attempt_distribution_centres(mi_distribution_centres_unfiltered)
      end
    end

    #####
    # select mi distribution centres by their distribution network e.g. 'EMMA' or 'MMRRC'
    #####
    def self.select_mi_distribution_centres_by_distribution_network(repository_name)
      mi_distribution_centres_unfiltered = Colony::DistributionCentre.joins(:colony).where("colony_distribution_centres.distribution_network = #{repository_name} AND colonies.mi_attempt_id IS NOT NULL").order(:id)
      return self.filter_gtc_mi_attempt_distribution_centres(mi_distribution_centres_unfiltered)
    end

    #####
    # Filter a list of mi attempt distribution centres down to those that are in state genotype confirmed
    # and are for a limited consortia set
    #####
    def self.filter_gtc_mi_attempt_distribution_centres(mi_distribution_centres_unfiltered)
      mi_distribution_centres = []

      mi_distribution_centres_unfiltered.each do |mi_distribution_centre|
        mi_attempt = mi_distribution_centre.colony.mi_attempt
        unless mi_attempt && mi_attempt.status.name == 'Genotype confirmed'
          next
        end
        # limit selection to specific consortia
        mi_consortium_name = mi_attempt.mi_plan.consortium.name
        if [ 'BaSH', 'JAX', 'DTCC' ].include? mi_consortium_name
        # if [ 'UCD-KOMP', 'DTCC-Legacy', 'MGP', 'MGP Legacy', 'EUCOMM-EUMODIC', 'MRC' ].include? mi_consortium_name
          mi_distribution_centres.push(mi_distribution_centre)
        end
      end

      return mi_distribution_centres
    end

    #####
    # get allele for mi distribution centre
    #####
    def self.get_allele_for_mi_distribution_centre(mi_distribution_centre)

      dc_allele_symbol_unsplit = mi_distribution_centre.colony.allele_symbol
      if ( dc_allele_symbol_unsplit.nil? )
        puts "WARN: Allele name #{dc_allele_symbol_unsplit} format not understood for Mi Attempt id #{mi_distribution_centre.colony.mi_attempt_id}, cannot reconcile"
        return
      end

      # strip out the superscript part of the allele symbol
      split_array = dc_allele_symbol_unsplit.match(/\w*<sup>(\S*)<\/sup>/)
      if ( split_array.nil? || split_array.length < 1 )
        puts "WARN: Allele name #{dc_allele_symbol_unsplit} format split length not correct for Mi Attempt id #{mi_distribution_centre.colony.mi_attempt_id}, cannot reconcile"
        return
      end

      dc_allele_symbol = split_array[1]
      if ( dc_allele_symbol.nil? )
        puts "WARN: No allele name found for Mi Attempt id #{mi_distribution_centre.colony.mi_attempt_id}, cannot reconcile"
        return
      end

      return dc_allele_symbol
    end

    #####
    # write results out to csv file
    #####
    def self.write_results_to_csv( mi_results, output_mi_filepath )
      if ( mi_results && mi_results.length > 0 )
        # grab hash keys as sorted array
        sorted_mi_keys = mi_results.keys.sort

        # write results out to mi_filepath passed as attribute
        CSV.open(output_mi_filepath, "wb") do |csv|

          # write Mi headers
          csv << ['repository','marker_symbol', 'mi_attempt_dc_id', 'mi_plan_id', 'consortium', 'allele', 'action', 'current_reconciled', 'exists_at_repo', 'available_at_repo', 'repo_alleles', 'new_reconciled' ]

          # iterate by marker symbol (gene)
          sorted_mi_keys.each do |mi_key|
            marker_symbol   = mi_key
            repository_name = mi_results[mi_key]['repository_name']

            # iterate over each distribution centre within a marker symbol
            sorted_mi_dc_keys = mi_results[mi_key]['distribution_centres'].keys.sort

            sorted_mi_dc_keys.each do |mi_dc_key|
              mi_dc_id            = mi_dc_key
              dc_h                = mi_results[mi_key]['distribution_centres'][mi_dc_key]
              mi_plan_id          = dc_h['mi_plan_id']
              consortium          = dc_h['consortium']
              allele              = dc_h['allele']
              current_reconciled  = dc_h['current_reconciled']
              action              = dc_h['action']

              # use repository details if anything found
              if dc_h.has_key?('repository_details')
                exists_at_repo    = dc_h['repository_details']['exists_at_repo']
                available_at_repo = dc_h['repository_details']['available_at_repo']

                if dc_h['repository_details'].has_key?('alleles')
                  array_alleles   = dc_h['repository_details']['alleles'].keys.sort
                  if array_alleles.length == 0
                    repo_alleles  = nil
                  else
                    repo_alleles    = array_alleles.join('|')
                  end
                end

                if dc_h['repository_details'].has_key?('new_reconciled')
                  new_reconciled  = dc_h['repository_details']['new_reconciled']
                end
              else
                exists_at_repo    = nil
                available_at_repo = nil
                repo_alleles      = nil
                new_reconciled    = nil
              end

              # write row for each mi attempt distribution centre
              csv << [repository_name, marker_symbol, mi_dc_id, mi_plan_id, consortium, allele, action, current_reconciled, exists_at_repo, available_at_repo, repo_alleles, new_reconciled ]
            end # dcs
          end # mi
        end # csv
      end # if mi_results
    end

end # end class

if __FILE__ == $0
  # this will only run if the script was the main, not load'd or require'd
  ReconcileMiAttemptDistributionCentres.new( nil ).reconcile_all_mi_attempt_distribution_centres
end