#!/usr/bin/env ruby

##
# This class handles reconciling Phenotype Attempt Distribution Centres in Imits against the specified
# repository.
# NB. currently only handles repository KOMP
##
class ReconcilePhenotypeAttemptDistributionCentres

  attr_accessor :repository_name
  attr_accessor :reposcraper

  EMMA_REPO_NAME  = 'EMMA'
  KOMP_REPO_NAME  = 'KOMP Repo'
  MMRRC_REPO_NAME = 'MMRRC'

  ##
  # Any initialization before running checks
  ##
  def initialize( repo_name, check_reconciled )
    # default to KOMP repo
    if ( repo_name.nil? )
      @repository_name = KOMP_REPO_NAME
      puts "Repository name passed in from rake task was nil, setting to default : #{@repository_name}"
    else
      @repository_name = repo_name
      puts "Repository name passed in from rake task : #{@repository_name}"
    end

    # default to not checking already reconciled phenotype attempt distribution centre (NB params are strings)
    if check_reconciled.nil?
      @check_reconciled = false
      puts "Check reconciled flag passed in from rake task was nil, setting to default : #{@check_reconciled}"
    else
      if check_reconciled == 'true'
        @check_reconciled = true
        puts "This run WILL check already reconciled Phenotype Distribution Centres"
      else
        @check_reconciled = false
        puts "This run will NOT check already reconciled Phenotype Distribution Centres"
      end
    end
  end

  ##
  # Reconcile all the Phenotype Attempt Distribution Centres for the selected repository
  ##
  def reconcile_all_phenotype_attempt_distribution_centres

    puts "Repository name: #{@repository_name}"
    puts "Check reconciled: #{@check_reconciled}"

    phenotype_distribution_centres = nil
    @reposcraper                   = nil

    case @repository_name
    when EMMA_REPO_NAME
      phenotype_distribution_centres = self.class.select_pa_distribution_centres_by_distribution_network(@repository_name)
      @reposcraper                   = ScraperEmmaRepository.new()
    when KOMP_REPO_NAME
      phenotype_distribution_centres = self.class.select_pa_distribution_centres_by_centre(@repository_name)
      @reposcraper                   = ScraperKompRepository.new()
    when MMRRC_REPO_NAME
      phenotype_distribution_centres = self.class.select_pa_distribution_centres_by_distribution_network(@repository_name)
      @reposcraper                   = ScraperMmrrcRepository.new()
    else
      puts "ERROR : repository name unrecognised when selecting phenotype_distribution_centres"
      return
    end # end case

    if phenotype_distribution_centres.nil?
      puts "No phenotype_distribution_centres found that meet criteria"
      return
    end

    puts "Number of phenotype attempt distribution centres selected = #{phenotype_distribution_centres.count()}"

    count_dcs_processed = 0
    count_dcs_skipped   = 0
    sleeptime_total     = 0

    phenotype_distribution_centres.each do |phenotype_distribution_centre|
      phenotype_attempt = phenotype_distribution_centre.phenotype_attempt

      puts "---------------------------------------------"
      puts "Phenotype Attempt [num #{count_dcs_processed + count_dcs_skipped + 1}] : #{phenotype_attempt.id}"

      mam                     = phenotype_attempt.mouse_allele_mod
      mi_plan                 = mam.mi_plan
      consortium_name         = mi_plan.consortium.name
      marker_symbol           = mi_plan.gene.marker_symbol
      geneid                  = mi_plan.gene.komp_repo_geneid
      phenotype_dc_reconciled = phenotype_distribution_centre.reconciled

      puts "Mouse Allele Mod id         = #{mam.id}"
      puts "Status                      = #{mam.status.name}"
      puts "Mi Plan id                  = #{mi_plan.id}"
      puts "Consortium name             = #{consortium_name}"
      puts "Marker symbol               = #{marker_symbol}"
      unless geneid.nil?
        puts "Komp Repo geneid in gene DB = #{geneid}"
      end
      if phenotype_dc_reconciled == "true"
        puts "Phenotype DC reconciled TRUE"
      elsif phenotype_dc_reconciled == "false"
        puts "Phenotype DC reconciled FALSE"
      elsif phenotype_dc_reconciled == "not checked"
        puts "Phenotype DC reconciled NOT CHECKED"
      else
        puts "Phenotype DC reconciled not set"
      end

      unless @check_reconciled
        # only those not already reconciled
        puts "Check if already reconciled"
        if phenotype_dc_reconciled == "true"
          puts "This Phenotype Attempt Distribution Centre is already reconciled"
          count_dcs_skipped += 1
          puts "Skipping this Phenotype Attempt Distribution Centre"
          puts "---------------------------------------------"
          next
        end
      end

      puts "Processing this Phenotype Attempt Distribution Centre"

      phenotype_distribution_centre.reconcile_with_repo( @repository_name, @reposcraper )
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
    puts "Total Phenotype Attempt Distribution Centres processed = #{count_dcs_processed}"
    puts "Total Phenotype Attempt Distribution Centres skipped   = #{count_dcs_skipped}"
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
  end # reconcile_all_phenotype_attempt_distribution_centres

  ##
  # Reconcile the Phenotype Attempt Distribution Centres for the selected repository and a specified gene
  ##
  # def reconcile_phenotype_attempt_distribution_centres_for_gene( marker_symbol )

  #   puts "Reconcile Phenotype Attempt Distribution Centres for gene : #{marker_symbol}"

  #   if ( marker_symbol.nil? )
  #     puts "ERROR: No marker symbol entered into method"
  #     return
  #   end

  #   # processing depends on repository
  #   case @repository_name
  #   when EMMA_REPO_NAME
  #     # _reconcile_emma_phenotype_attempt_distribution_centres_for_gene( marker_symbol )
  #     puts "NOT IMPLEMENTED YET (#{marker_symbol})"
  #   when KOMP_REPO_NAME
  #     _reconcile_komp_phenotype_attempt_distribution_centres_for_gene( marker_symbol )
  #   when MMRRC_REPO_NAME
  #     # _reconcile_mmrrc_phenotype_attempt_distribution_centres_for_gene( marker_symbol )
  #     puts "NOT IMPLEMENTED YET (#{marker_symbol})"
  #   else
  #     puts "ERROR : repository name unrecognised when reconciling Phenotype Attempt"
  #     return
  #   end # end case

  # end # reconcile_phenotype_attempt_distribution_centres_for_gene

  ##
  # Reconcile the Phenotype Attempt Distribution Centres for the KOMP repository and a specified gene
  ##
  # def _reconcile_komp_phenotype_attempt_distribution_centres_for_gene( marker_symbol )

  #   puts "Reconcile KOMP repository Phenotype Attempt Distribution Centres for gene : #{marker_symbol}"

  #   # find gene for marker symbol
  #   gene = Gene.find_by_marker_symbol( marker_symbol )

  #   if ( gene.nil? )
  #     puts "ERROR : no gene located for marker symbol #{marker_symbol} in Imits"
  #     return
  #   end

  #   geneid = gene.komp_repo_geneid

  #   # create a new repository scraper instance
  #   puts "Creating Repo Scraper instance"
  #   if ( @reposcraper.nil? )
  #     @reposcraper = ScraperKompRepository.new()
  #   end

  #   # attempt to scrape the geneid from the KOMP website
  #   if ( geneid.nil? )
  #     geneid = @reposcraper.fetch_komp_geneid_for_marker_symbol( marker_symbol )
  #   end

  #   if ( geneid.nil? )
  #     puts "ERROR: geneid not found for #{marker_symbol}, cannot continue"
  #     return
  #   end
  #   puts "Found geneid = #{geneid} for #{marker_symbol}"

  #   # for mi_plans find phenotype_attempts
  #   # puts "Check Mi Plans for gene #{gene.marker_symbol}"
  #   mi_plans = gene.mi_plans
  #   mi_plans.each do |mi_plan|

  #     # puts "Check the Mouse Allele Mods for Mi Plan id #{mi_plan.id}"
  #     mouse_allele_mods = mi_plan.mouse_allele_mods
  #     mouse_allele_mods.each do |mouse_allele_mod|

  #       # puts "Check Mouse Allele Mod with id #{mouse_allele_mod.id}"
  #       unless mouse_allele_mod.status.name == 'Cre Excision Complete'
  #           puts "Rejected Mouse Allele Mod, status #{mouse_allele_mod.status.name}"
  #           next
  #       end

  #       # puts "Checking Distribution Centres for Mouse Allele Mod id #{mouse_allele_mod.id}"
  #       phenotype_distribution_centres = mouse_allele_mod.distribution_centres
  #       phenotype_distribution_centres.each do |phenotype_distribution_centre|

  #           puts "Reconcile Mi Plan id #{mi_plan.id} Mouse Allele Mod id #{mouse_allele_mod.id} at Distribution Centre #{phenotype_distribution_centre.id}"
  #           phenotype_distribution_centre.reconcile_with_repo( @repository_name, @reposcraper )
  #       end # distribution_centres
  #     end # phenotype_attempts
  #   end # mi_plans
  # end # _reconcile_komp_phenotype_attempt_distribution_centres_for_gene

  private
    #####
    # select phenotype attempt distribution centres by relation to a repository centre e.g. 'KOMP Repo'
    #####
    def self.select_pa_distribution_centres_by_centre(repository_name)
      puts "Selecting phenotype attempt distribution centres by Centre: #{repository_name}"
      repository_centre = Centre.find_by_name(repository_name)

      if repository_centre.nil?
        puts "ERROR : repository centre not found for #{repository_name}"
      else
        # N.B. can change filter in the Centre model to affect the data selected for update
        pa_distribution_centres_unfiltered = repository_centre.phenotype_attempt_distribution_centres
        return self.filter_cre_excised_phenotype_attempt_distribution_centres(pa_distribution_centres_unfiltered)
      end
    end

    #####
    # select phenotype attempt distribution centres by their distribution network e.g. 'EMMA' or 'MMRRC'
    #####
    def self.select_pa_distribution_centres_by_distribution_network(repository_name)
      puts "Selecting phenotype attempt distribution centres by distribution network: #{repository_name}"
      pa_distribution_centres_unfiltered = PhenotypeAttempt::DistributionCentre.where("distribution_network = ?", repository_name).order(:id)
      return self.filter_cre_excised_phenotype_attempt_distribution_centres(pa_distribution_centres_unfiltered)
    end

    #####
    # Filter a list of phenotype attempt distribution centres down to those that are Cre excised
    # and are for a limited consortia set
    #####
    def self.filter_cre_excised_phenotype_attempt_distribution_centres(pa_distribution_centres_unfiltered)

      pa_distribution_centres = []

      pa_distribution_centres_unfiltered.each do |phenotype_distribution_centre|
        mouse_allele_mod = phenotype_distribution_centre.mouse_allele_mod
        if mouse_allele_mod.nil?
          next
        end
        unless mouse_allele_mod.status.name == 'Cre Excision Complete'
          next
        end
        # limit selection to specific consortia
        pa_consortium_name = mouse_allele_mod.mi_plan.consortium.name
        if [ 'BaSH', 'JAX', 'DTCC' ].include? pa_consortium_name
        # if [ 'UCD-KOMP', 'DTCC-Legacy', 'MGP', 'MGP Legacy', 'EUCOMM-EUMODIC', 'MRC' ].include? pa_consortium_name
          pa_distribution_centres.push(phenotype_distribution_centre)
        end
      end

      return pa_distribution_centres
    end

end # end class

if __FILE__ == $0
  # this will only run if the script was the main, not load'd or require'd
  ReconcilePhenotypeAttemptDistributionCentres.new( nil ).reconcile_all_phenotype_attempt_distribution_centres
end