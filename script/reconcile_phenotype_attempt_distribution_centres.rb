#!/usr/bin/env ruby

##
# This class handles reconciling Phenotype Attempt Distribution Centres in Imits against the specified
# repository.
# NB. currently only handles repository KOMP
##
class ReconcilePhenotypeAttemptDistributionCentres

  attr_accessor :repository_name
  attr_accessor :reposcraper

  KOMP_REPO_NAME = 'KOMP Repo'

  ##
  # Any initialization before running checks
  ##
  def initialize( repo_name )
    # default to KOMP repo
    if ( repo_name.nil? )
      @repository_name = KOMP_REPO_NAME
      puts "Repository name passed in from rake task was nil, setting to default : #{@repository_name}"
    else
      @repository_name = repo_name
      puts "Repository name passed in from rake task : #{@repository_name}"
    end
  end

  ##
  # Reconcile all the Phenotype Attempt Distribution Centres for the selected repository
  ##
  def reconcile_all_phenotype_attempt_distribution_centres

    puts "Reconciling All Phenotype Attempt Distribution Centres"

    repository_centre = Centre.find_by_name( @repository_name )

    # NB can change filter in the Centre model to effect the Phenotype's selected for update, default all
    phenotype_distribution_centres = repository_centre.get_all_cre_excised_phenotype_attempt_distribution_centres
    puts "Number of phenotype attempt distribution centres selected = #{phenotype_distribution_centres.count()}"

    count_dcs_processed = 0
    sleeptime_total     = 0

    phenotype_distribution_centres.each do |phenotype_distribution_centre|
        phenotype_attempt = phenotype_distribution_centre.phenotype_attempt

        puts "---------------------------------------------"
        puts "Phenotype Attempt [num #{count_dcs_processed + 1}] : #{phenotype_attempt.id}"
        mam = phenotype_attempt.mouse_allele_mod
        puts "Mouse Allele Mod id = #{mam.id}"
        puts "Status = #{mam.status.name}"
        mi_plan = mam.mi_plan
        puts "Mi Plan id = #{mi_plan.id}"
        consortium_name = mi_plan.consortium.name
        puts "Consortium name = #{consortium_name}"
        marker_symbol = mi_plan.gene.marker_symbol
        puts "Marker symbol = #{marker_symbol}"
        geneid = mi_plan.gene.komp_repo_geneid
        puts "Komp Repo geneid = #{geneid}"

        if ( @reposcraper.nil? )
            @reposcraper = RepositoryGeneDetailsScraper.new()
        end
        phenotype_distribution_centre.reconcile_with_repo( @repository_name, @reposcraper )
        puts "---------------------------------------------"
        count_dcs_processed += 1

        # delay for random time in seconds before processing
        unless count_dcs_processed == 1
            sleeptime = rand(5)
            sleep(3 + sleeptime)
            sleeptime_total = sleeptime_total + sleeptime + 3
        end
    end
    puts '============================================================'
    puts "Total Phenotype Attempt Distribution Centres processed = #{count_dcs_processed}"
    puts '============================================================'
    puts "Total products 'mice' found         = #{@reposcraper.count_is_mice}"
    puts "Total products 'recovery' found     = #{@reposcraper.count_is_recovery}"
    puts "Total products 'germ plasm' found   = #{@reposcraper.count_is_germ_plasm}"
    puts "Total products 'embryos' found      = #{@reposcraper.count_is_embryos}"
    puts "Total alleles found                 = #{@reposcraper.count_unique_alleles_found}"
    puts "Total alleles found with products   = #{@reposcraper.count_unique_alleles_with_products}"
    puts "Total time sleeping between scrapes = #{sleeptime_total} seconds"
    puts "------------------------------------------------------------"
  end # reconcile_all_phenotype_attempt_distribution_centres

  ##
  # Reconcile the Phenotype Attempt Distribution Centres for the selected repository and a specified gene
  ##
  def reconcile_phenotype_attempt_distribution_centres_for_gene( marker_symbol )

    puts "Reconcile Phenotype Attempt Distribution Centres for gene : #{marker_symbol}"

    if ( marker_symbol.nil? )
      puts "ERROR: No marker symbol entered into method"
      return
    end

    # for KOMP repository we need the geneid
    case @repository_name
    when KOMP_REPO_NAME
      _reconcile_komp_phenotype_attempt_distribution_centres_for_gene( marker_symbol )
    else
      puts "ERROR : repository name unrecognised when selecting geneid from database"
      return
    end
  end # reconcile_phenotype_attempt_distribution_centres_for_gene

  ##
  # Reconcile the Phenotype Attempt Distribution Centres for the KOMP repository and a specified gene
  ##
  def _reconcile_komp_phenotype_attempt_distribution_centres_for_gene( marker_symbol )

    puts "Reconcile KOMP repository Phenotype Attempt Distribution Centres for gene : #{marker_symbol}"

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
      @reposcraper = RepositoryGeneDetailsScraper.new()
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

    # for mi_plans find phenotype_attempts
    # puts "Check Mi Plans for gene #{gene.marker_symbol}"
    mi_plans = gene.mi_plans
    mi_plans.each do |mi_plan|

      # puts "Check the Mouse Allele Mods for Mi Plan id #{mi_plan.id}"
      mouse_allele_mods = mi_plan.mouse_allele_mods
      mouse_allele_mods.each do |mouse_allele_mod|

        # puts "Check Mouse Allele Mod with id #{mouse_allele_mod.id}"
        unless mouse_allele_mod.status.name == 'Cre Excision Complete'
            puts "Rejected Mouse Allele Mod, status #{mouse_allele_mod.status.name}"
            next
        end

        # puts "Checking Distribution Centres for Mouse Allele Mod id #{mouse_allele_mod.id}"
        phenotype_distribution_centres = mouse_allele_mod.distribution_centres
        phenotype_distribution_centres.each do |phenotype_distribution_centre|

            puts "Reconcile Mi Plan id #{mi_plan.id} Mouse Allele Mod id #{mouse_allele_mod.id} at Distribution Centre #{phenotype_distribution_centre.id}"
            phenotype_distribution_centre.reconcile_with_repo( CENTRE_NAME, @reposcraper )
        end # distribution_centres
      end # phenotype_attempts
    end # mi_plans
  end # _reconcile_komp_phenotype_attempt_distribution_centres_for_gene
end # end class

if __FILE__ == $0
  # this will only run if the script was the main, not load'd or require'd
  ReconcilePhenotypeAttemptDistributionCentres.new( nil ).reconcile_all_phenotype_attempt_distribution_centres
end