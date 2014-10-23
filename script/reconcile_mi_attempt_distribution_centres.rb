#!/usr/bin/env ruby

##
# This class handles reconciling Mi Attempt Distribution Centres in Imits against the specified
# repository.
# NB. currently only handles repository KOMP
##
class ReconcileMiAttemptDistributionCentres

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
  # Reconcile all the Mi Attempt Distribution Centres for the selected repository
  ##
  def reconcile_all_mi_attempt_distribution_centres

    puts "Reconciling All Mi Attempt Distribution Centres"

    repository_centre = Centre.find_by_name( @repository_name )

    # NB can change filter in the Centre model to effect the Mi's selected for update, default all
    mi_distribution_centres = repository_centre.get_all_gtc_mi_attempt_distribution_centres
    puts "Number of mi attempt distribution centres selected = #{mi_distribution_centres.count()}"

    count_dcs_processed = 0
    sleeptime_total     = 0

    mi_distribution_centres.each do |mi_distribution_centre|
        mi_attempt = mi_distribution_centre.mi_attempt

        puts "---------------------------------------------"
        puts "Mi Attempt [num #{count_dcs_processed + 1}] : #{mi_attempt.id}"
        puts "Status = #{mi_attempt.status.name}"
        mi_plan = mi_attempt.mi_plan
        consortium_name = mi_plan.consortium.name
        puts "Consortium = #{consortium_name}"
        marker_symbol = mi_plan.gene.marker_symbol
        puts "Marker symbol = #{marker_symbol}"
        geneid = mi_plan.gene.komp_repo_geneid
        puts "Komp Repo geneid = #{geneid}"

        if ( @reposcraper.nil? )
            @reposcraper = RepositoryGeneDetailsScraper.new()
        end
        mi_distribution_centre.reconcile_with_repo( @repository_name, @reposcraper )
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
    puts "Total Mi Attempt Distribution Centres processed = #{count_dcs_processed}"
    puts '============================================================'
    puts "Total products 'mice' found         = #{@reposcraper.count_is_mice}"
    puts "Total products 'recovery' found     = #{@reposcraper.count_is_recovery}"
    puts "Total products 'germ plasm' found   = #{@reposcraper.count_is_germ_plasm}"
    puts "Total products 'embryos' found      = #{@reposcraper.count_is_embryos}"
    puts "Total alleles found                 = #{@reposcraper.count_unique_alleles_found}"
    puts "Total alleles found with products   = #{@reposcraper.count_unique_alleles_with_products}"
    puts "Total time sleeping between scrapes = #{sleeptime_total} seconds"
    puts "------------------------------------------------------------"
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

    # for KOMP repository we need the geneid
    case @repository_name
    when KOMP_REPO_NAME
      _reconcile_komp_mi_attempt_distribution_centres_for_gene( marker_symbol )
    else
      puts "ERROR : repository name unrecognised when selecting geneid from database"
      return
    end
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
        mi_distribution_centres = mi_attempt.distribution_centres
        mi_distribution_centres.each do |mi_distribution_centre|

            puts "Reconcile Mi Plan id #{mi_plan.id} Mi Attempt id #{mi_attempt.id} at Distribution Centre #{mi_distribution_centre.id}"
            mi_distribution_centre.reconcile_with_repo( @repository_name, @reposcraper )
        end # distribution_centres
      end # mi_attempts
    end # mi_plans
  end # _reconcile_komp_mi_attempt_distribution_centres_for_gene
end # end class

if __FILE__ == $0
  # this will only run if the script was the main, not load'd or require'd
  ReconcileMiAttemptDistributionCentres.new( nil ).reconcile_all_mi_attempt_distribution_centres
end