#!/usr/bin/env ruby

##
# This class checks any unreconciled Komp distribution centres to see if they are mistakenly recorded at the MMRRC
##
class CheckUnreconciledKompWithMmrrc

  require 'csv'

  KOMP_REPO_NAME  = 'KOMP Repo'
  MMRRC_REPO_NAME = 'MMRRC'

  ##
  # Any initialization before running checks
  ##
  def initialize( mi_filepath, pa_filepath )
    puts "In initialize"

    if ( mi_filepath.nil? )
      @output_mi_filepath = '/nfs/team87/tmp/unreconciled_komp_mi_dc_data.csv'
      # puts "Mi attempt filepath passed in from rake task was nil, setting to default : #{@output_mi_filepath}"
    else
      @output_mi_filepath = repo_name
      # puts "Mi attempt filepath passed in from rake task : #{@output_mi_filepath}"
    end

    if ( pa_filepath.nil? )
      @output_pa_filepath = '/nfs/team87/tmp/unreconciled_komp_pa_dc_data.csv'
      # puts "Phenotype attempt filepath passed in from rake task was nil, setting to default : #{@output_pa_filepath}"
    else
      @output_pa_filepath = repo_name
      # puts "Phenotype attempt filepath passed in from rake task : #{@output_pa_filepath}"
    end

  end

  def check_komp_distribution_centres
    puts "Checking for unreconciled Mi attempt distribution centres"
    mi_results = self.class.check_mi_distribution_centres
    self.class.write_mi_attempt_results_to_csv( mi_results, @output_mi_filepath )

    puts "Checking for unreconciled Phenotype attempt distribution centres"
    pa_results = self.class.check_pa_distribution_centres
    self.class.write_phenotype_attempt_results_to_csv( pa_results, @output_pa_filepath )

    puts "Script Finished"
    puts "Mi attempt results csv at:        #{@output_mi_filepath}"
    puts "Phenotype attempt results csv at: #{@output_pa_filepath}"
  end

  private

    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    # Mi Attempt DCs
    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    #####
    # check whether mi distribution centre allele and repository allele match
    #####
    def self.check_mi_distribution_centres
      puts "In check for Mi Distribution Centres"
      mi_results = {}

      @reposcraper = ScraperMmrrcRepository.new()

      unreconciled_mi_distribution_centres = self.select_unreconciled_komp_mi_distribution_centres

      count_unreconciled_mi_dcs_checked              = 0
      count_unreconciled_mi_dcs_not_at_mmrrc         = 0
      count_unreconciled_mi_dcs_exist_at_mmrrc       = 0
      count_unreconciled_mi_dcs_available_at_mmrrc   = 0
      count_unreconciled_mi_dcs_unavailable_at_mmrrc = 0
      count_errors_checking_mi_alleles               = 0
      sleeptime_total                                = 0

      unreconciled_mi_distribution_centres.each do |mi_distribution_centre|

        count_unreconciled_mi_dcs_checked += 1

        mi_attempt = mi_distribution_centre.mi_attempt
        puts "---------------------------------------------"
        puts "Mi Attempt [num #{count_unreconciled_mi_dcs_checked}] : #{mi_attempt.id}"
        mi_plan          = mi_attempt.mi_plan
        consortium_name  = mi_plan.consortium.name
        marker_symbol    = mi_plan.gene.marker_symbol

        puts "Mi Plan ID    = #{mi_plan.id}"
        puts "Consortium    = #{consortium_name}"
        puts "Marker symbol = #{marker_symbol}"

        # scrape MMRRC website to see if unreconciled Mi DC has allele there
        gene_repo_details = mi_distribution_centre.reconcile_with_mmrrc_repo( @reposcraper )

        # add to results hash, keyed on marker symbol and mi dc id
        unless mi_results.has_key?(marker_symbol)
          mi_results[marker_symbol] = {
            'marker_symbol'        => marker_symbol,
            'distribution_centres' => {}
          }
        end

        mi_allele = self.get_allele_for_mi_distribution_centre(mi_distribution_centre)

        mi_results[marker_symbol]['distribution_centres'][mi_distribution_centre.id] = {
          'mi_dc_id'           => mi_distribution_centre.id,
          'mi_plan_id'         => mi_plan.id,
          'consortium'         => consortium_name,
          'allele'             => mi_allele
        }

        if ( gene_repo_details.nil? || gene_repo_details['alleles'].count == 0 )
          puts "WARN: No gene details found for this gene at MMRRC"
          mi_results[marker_symbol]['distribution_centres'][mi_distribution_centre.id]['exists_at_mmrrc'] = false
          mi_results[marker_symbol]['distribution_centres'][mi_distribution_centre.id]['available_at_mmrrc'] = false
          count_unreconciled_mi_dcs_not_at_mmrrc += 1
        else
          exists_at_mmrrc, available_at_mmrrc = self.check_mi_alleles_match(mi_distribution_centre, gene_repo_details)
          if ( exists_at_mmrrc.nil? || available_at_mmrrc.nil? )
            puts "Failed check for allele at MMRRC"
            mi_results[marker_symbol]['distribution_centres'][mi_distribution_centre.id]['exists_at_mmrrc'] = false
            mi_results[marker_symbol]['distribution_centres'][mi_distribution_centre.id]['available_at_mmrrc'] = false
            count_errors_checking_mi_alleles += 1
          else
            if exists_at_mmrrc
              puts "Exists at MMRRC"
              mi_results[marker_symbol]['distribution_centres'][mi_distribution_centre.id]['exists_at_mmrrc'] = true
              count_unreconciled_mi_dcs_exist_at_mmrrc += 1

              if available_at_mmrrc
                puts "Available at MMRRC"
                mi_results[marker_symbol]['distribution_centres'][mi_distribution_centre.id]['available_at_mmrrc'] = true
                count_unreconciled_mi_dcs_available_at_mmrrc += 1
              else
                puts "Not available at MMRRC"
                mi_results[marker_symbol]['distribution_centres'][mi_distribution_centre.id]['available_at_mmrrc'] = false
                count_unreconciled_mi_dcs_unavailable_at_mmrrc += 1
              end
            else
              puts "Does not exist at MMRRC"
              mi_results[marker_symbol]['distribution_centres'][mi_distribution_centre.id]['exists_at_mmrrc'] = false
            mi_results[marker_symbol]['distribution_centres'][mi_distribution_centre.id]['available_at_mmrrc'] = false
              count_unreconciled_mi_dcs_not_at_mmrrc += 1
            end
          end
        end

        puts "---------------------------------------------"

        # delay for random time in seconds before processing
        unless count_unreconciled_mi_dcs_checked == unreconciled_mi_distribution_centres.count()
          sleeptime = rand(5)
          sleep(3 + sleeptime)
          sleeptime_total = sleeptime_total + sleeptime + 3
        end
      end # each mi_distribution_centre

      puts '============================================================'
      puts "Total Mi Attempt Distribution Centres processed = #{count_unreconciled_mi_dcs_checked}"
      puts '============================================================'
      puts "Count where not found at the MMRRC          = #{count_unreconciled_mi_dcs_not_at_mmrrc}"
      puts "Count where allele exists at MMRRC          = #{count_unreconciled_mi_dcs_exist_at_mmrrc}"
      puts "Count where products available at MMRRC     = #{count_unreconciled_mi_dcs_available_at_mmrrc}"
      puts "Count where products NOT available at MMRRC = #{count_unreconciled_mi_dcs_unavailable_at_mmrrc}"
      puts "------------------------------------------------------------"
      puts "Total sleep time                            = #{sleeptime_total}"
      puts "Count where errors checking alleles         = #{count_errors_checking_mi_alleles}"
      puts '============================================================'

      return mi_results
    end

    #####
    # check whether mi distribution centre allele and repository allele match
    #####
    def self.check_mi_alleles_match(mi_distribution_centre, gene_repo_details)

      dc_allele_symbol = get_allele_for_mi_distribution_centre(mi_distribution_centre)
      if dc_allele_symbol.nil?
        return
      end

      puts "Sanger Mi Attempt allele : #{dc_allele_symbol}"

      if gene_repo_details['alleles'].has_key?(dc_allele_symbol)
        matching_allele = gene_repo_details['alleles'][dc_allele_symbol]

        puts "Found matching allele at MMRRC : #{matching_allele}"

        # any match counts as reconciled
        if (( matching_allele['is_mice'] == 1 ) || ( matching_allele['is_recovery'] == 1 ) ||
           ( matching_allele['is_germ_plasm'] == 1 ) || ( matching_allele['is_embryos'] == 1 ))
          puts "Allele is available to order at MMRRC"
          return true, true
        else
          puts "Allele is not available to order at MMRRC"
          return true, false
        end # check for availability of products
      else
        puts "WARN: No repository allele found to match to Mi Attempt allele #{dc_allele_symbol}"
        return false, false
      end # check for matching allele
    end

    #####
    # get allele for mi distribution centre
    #####
    def self.get_allele_for_mi_distribution_centre(mi_distribution_centre)

      dc_allele_symbol_unsplit = mi_distribution_centre.mi_attempt.allele_symbol
      if ( dc_allele_symbol_unsplit.nil? )
        puts "WARN: Allele name #{dc_allele_symbol_unsplit} format not understood for Mi Attempt id #{mi_distribution_centre.mi_attempt.id}, cannot reconcile"
        return
      end

      # strip out the superscript part of the allele symbol
      split_array = dc_allele_symbol_unsplit.match(/\w*<sup>(\S*)<\/sup>/)
      if ( split_array.nil? || split_array.length < 1 )
        puts "WARN: Allele name #{dc_allele_symbol_unsplit} format split length not correct for Mi Attempt id #{mi_distribution_centre.mi_attempt.id}, cannot reconcile"
        return
      end

      dc_allele_symbol = split_array[1]
      if ( dc_allele_symbol.nil? )
        puts "WARN: No allele name found for Mi Attempt id #{mi_distribution_centre.mi_attempt.id}, cannot reconcile"
        return
      end

      return dc_allele_symbol
    end

    #####
    # select mi distribution centres by relation to a repository centre e.g. 'KOMP Repo'
    #####
    def self.select_unreconciled_komp_mi_distribution_centres
      repository_centre = Centre.find_by_name(KOMP_REPO_NAME)

      if repository_centre.nil?
        puts "ERROR : repository centre not found for #{repository_name}"
        return
      else
        all_mi_distribution_centres = repository_centre.mi_attempt_distribution_centres

        unreconciled_mi_distribution_centres = []
        count_mi_dcs_checked      = 0
        count_mi_dcs_unreconciled = 0

        all_mi_distribution_centres.each do |mi_distribution_centre|
          count_mi_dcs_checked += 1

          mi_dc_reconciled = mi_distribution_centre.reconciled
          if mi_dc_reconciled == "false"
            count_mi_dcs_unreconciled += 1
            unreconciled_mi_distribution_centres.push(mi_distribution_centre)
          end
        end # each mi distribution centre

        puts "Komp Mi Attempt Distribution Centres checked      = #{count_mi_dcs_checked}"
        puts "Komp Mi Attempt Distribution Centres unreconciled = #{count_mi_dcs_unreconciled}"

        return unreconciled_mi_distribution_centres
      end # check on repository centre
    end

    #####
    # write results out to csv file
    #####
    def self.write_mi_attempt_results_to_csv( mi_results, output_mi_filepath )
      if ( mi_results && mi_results.length > 0 )
        # grab hash keys as sorted array
        sorted_mi_keys = mi_results.keys.sort

        # write results out to mi_filepath passed as attribute
        CSV.open(output_mi_filepath, "wb") do |csv|

          # write Mi headers
          csv << ['marker_symbol', 'mi_attempt_dc_id', 'mi_plan_id', 'consortium', 'allele', 'exists_at_mmrrc', 'available_at_mmrrc' ]

          # iterate over sorted keys array and write csv lines
          sorted_mi_keys.each do |mi_key|
            marker_symbol = mi_key

            # might be more than one distribution centre for an mi attempt
            sorted_mi_dc_keys = mi_results[mi_key]['distribution_centres'].keys.sort

            sorted_mi_dc_keys.each do |mi_dc_key|
              mi_dc_id           = mi_dc_key
              dc_h               = mi_results[mi_key]['distribution_centres'][mi_dc_key]
              mi_plan_id         = dc_h['mi_plan_id']
              consortium         = dc_h['consortium']
              allele             = dc_h['allele']
              exists_at_mmrrc    = dc_h['exists_at_mmrrc']
              available_at_mmrrc = dc_h['available_at_mmrrc']

              # write row for each mi attempt distribution centre
              csv << [marker_symbol, mi_dc_id, mi_plan_id, consortium, allele, exists_at_mmrrc, available_at_mmrrc ]
            end # dcs
          end # mi
        end # csv
      end # if mi_results
    end

    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    # Phenotype Attempt DCs
    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    #####
    # check whether phenotype distribution centre allele and repository allele match
    #####
    def self.check_pa_distribution_centres
      puts "In check for Pa Distribution Centres"
      pa_results = {}

      @reposcraper = ScraperMmrrcRepository.new()

      unreconciled_pa_distribution_centres = self.select_unreconciled_komp_pa_distribution_centres

      count_unreconciled_pa_dcs_checked              = 0
      count_unreconciled_pa_dcs_not_at_mmrrc         = 0
      count_unreconciled_pa_dcs_exist_at_mmrrc       = 0
      count_unreconciled_pa_dcs_available_at_mmrrc   = 0
      count_unreconciled_pa_dcs_unavailable_at_mmrrc = 0
      count_errors_checking_pa_alleles               = 0
      sleeptime_total                                = 0

      unreconciled_pa_distribution_centres.each do |pa_distribution_centre|

        count_unreconciled_pa_dcs_checked += 1

        phenotype_attempt = pa_distribution_centre.phenotype_attempt

        puts "---------------------------------------------"
        puts "Phenotype Attempt [num #{count_unreconciled_pa_dcs_checked}] : #{phenotype_attempt.id}"

        mam                     = phenotype_attempt.mouse_allele_mod
        mi_plan                 = mam.mi_plan
        consortium_name         = mi_plan.consortium.name
        marker_symbol           = mi_plan.gene.marker_symbol

        # scrape MMRRC website to see if unreconciled Pa DC has allele there
        gene_repo_details       = pa_distribution_centre.reconcile_with_mmrrc_repo( @reposcraper )

        # add to results hash, keyed on marker symbol and Pa dc id
        unless pa_results.has_key?(marker_symbol)
          pa_results[marker_symbol] = {
            'marker_symbol'        => marker_symbol,
            'distribution_centres' => {}
          }
        end

        pa_allele = self.get_allele_for_pa_distribution_centre(pa_distribution_centre)

        pa_results[marker_symbol]['distribution_centres'][pa_distribution_centre.id] = {
          'pa_dc_id'           => pa_distribution_centre.id,
          'mi_plan_id'         => mi_plan.id,
          'consortium'         => consortium_name,
          'allele'             => pa_allele
        }

        if ( gene_repo_details.nil? || gene_repo_details['alleles'].count == 0 )
          puts "WARN: No gene details found for this gene at MMRRC"
          pa_results[marker_symbol]['distribution_centres'][pa_distribution_centre.id]['exists_at_mmrrc'] = false
          pa_results[marker_symbol]['distribution_centres'][pa_distribution_centre.id]['available_at_mmrrc'] = false
          count_unreconciled_pa_dcs_not_at_mmrrc += 1
        else
          exists_at_mmrrc, available_at_mmrrc = self.check_pa_alleles_match(pa_distribution_centre, gene_repo_details)
          if ( exists_at_mmrrc.nil? || available_at_mmrrc.nil? )
            puts "Failed check for allele at MMRRC"
            pa_results[marker_symbol]['distribution_centres'][pa_distribution_centre.id]['exists_at_mmrrc'] = false
            pa_results[marker_symbol]['distribution_centres'][pa_distribution_centre.id]['available_at_mmrrc'] = false
            count_errors_checking_pa_alleles += 1
          else
            if exists_at_mmrrc
              puts "Exists at MMRRC"
              pa_results[marker_symbol]['distribution_centres'][pa_distribution_centre.id]['exists_at_mmrrc'] = true
              count_unreconciled_pa_dcs_exist_at_mmrrc += 1

              if available_at_mmrrc
                puts "Available at MMRRC"
                pa_results[marker_symbol]['distribution_centres'][pa_distribution_centre.id]['available_at_mmrrc'] = true
                count_unreconciled_pa_dcs_available_at_mmrrc += 1
              else
                puts "Not available at MMRRC"
                pa_results[marker_symbol]['distribution_centres'][pa_distribution_centre.id]['available_at_mmrrc'] = false
                count_unreconciled_pa_dcs_unavailable_at_mmrrc += 1
              end
            else
              puts "Does not exist at MMRRC"
              pa_results[marker_symbol]['distribution_centres'][pa_distribution_centre.id]['exists_at_mmrrc'] = false
              pa_results[marker_symbol]['distribution_centres'][pa_distribution_centre.id]['available_at_mmrrc'] = false
              count_unreconciled_pa_dcs_not_at_mmrrc += 1
            end
          end
        end

        puts "---------------------------------------------"

        # delay for random time in seconds before processing
        unless count_unreconciled_pa_dcs_checked == unreconciled_pa_distribution_centres.count()
          sleeptime = rand(5)
          sleep(3 + sleeptime)
          sleeptime_total = sleeptime_total + sleeptime + 3
        end
      end # each pa_distribution_centre

      puts '============================================================'
      puts "Total Phenotype Attempt Distribution Centres processed = #{count_unreconciled_pa_dcs_checked}"
      puts '============================================================'
      puts "Count where not found at the MMRRC          = #{count_unreconciled_pa_dcs_not_at_mmrrc}"
      puts "Count where allele exists at MMRRC          = #{count_unreconciled_pa_dcs_exist_at_mmrrc}"
      puts "Count where products available at MMRRC     = #{count_unreconciled_pa_dcs_available_at_mmrrc}"
      puts "Count where products NOT available at MMRRC = #{count_unreconciled_pa_dcs_unavailable_at_mmrrc}"
      puts "------------------------------------------------------------"
      puts "Total sleep time                            = #{sleeptime_total}"
      puts "Count where errors checking alleles         = #{count_errors_checking_pa_alleles}"
      puts '============================================================'

      return pa_results
    end

    #####
    # check whether pa distribution centre allele and repository allele match
    #####
    def self.check_pa_alleles_match(pa_distribution_centre, gene_repo_details)

      dc_allele_symbol = get_allele_for_pa_distribution_centre(pa_distribution_centre)
      if dc_allele_symbol.nil?
        return
      end

      puts "Sanger Phenotype Attempt allele : #{dc_allele_symbol}"

      if gene_repo_details['alleles'].has_key?(dc_allele_symbol)
        matching_allele = gene_repo_details['alleles'][dc_allele_symbol]

        puts "Found matching allele at MMRRC : #{matching_allele}"

        # any match counts as reconciled
        if (( matching_allele['is_mice'] == 1 ) || ( matching_allele['is_recovery'] == 1 ) ||
           ( matching_allele['is_germ_plasm'] == 1 ) || ( matching_allele['is_embryos'] == 1 ))
          puts "Allele is available to order at MMRRC"
          return true, true
        else
          puts "Allele is not available to order at MMRRC"
          return true, false
        end # check for availability of products
      else
        puts "WARN: No repository allele found to match to Phenotype Attempt allele #{dc_allele_symbol}"
        return false, false
      end # check for matching allele
    end

    #####
    # get allele for pa distribution centre
    #####
    def self.get_allele_for_pa_distribution_centre(pa_distribution_centre)

      dc_allele_symbol_unsplit = pa_distribution_centre.phenotype_attempt.allele_symbol
      if ( dc_allele_symbol_unsplit.nil? )
        puts "WARN: Allele name #{dc_allele_symbol_unsplit} format not understood for Phenotype Attempt id #{pa_distribution_centre.phenotype_attempt.id}, cannot reconcile"
        return
      end

      # strip out the superscript part of the allele symbol
      split_array = dc_allele_symbol_unsplit.match(/\w*<sup>(\S*)<\/sup>/)
      if ( split_array.nil? || split_array.length < 1 )
        puts "WARN: Allele name #{dc_allele_symbol_unsplit} format split length not correct for Phenotype Attempt id #{pa_distribution_centre.phenotype_attempt.id}, cannot reconcile"
        return
      end

      dc_allele_symbol = split_array[1]
      if ( dc_allele_symbol.nil? )
        puts "WARN: No allele name found for Phenotype Attempt id #{pa_distribution_centre.phenotype_attempt.id}, cannot reconcile"
        return
      end

      return dc_allele_symbol
    end

    #####
    # select pa distribution centres by relation to a repository centre e.g. 'KOMP Repo'
    #####
    def self.select_unreconciled_komp_pa_distribution_centres
      repository_centre = Centre.find_by_name(KOMP_REPO_NAME)

      if repository_centre.nil?
        puts "ERROR : repository centre not found for #{repository_name}"
        return
      else
        all_pa_distribution_centres = repository_centre.phenotype_attempt_distribution_centres

        unreconciled_pa_distribution_centres = []
        count_pa_dcs_checked      = 0
        count_pa_dcs_unreconciled = 0

        all_pa_distribution_centres.each do |pa_distribution_centre|
          count_pa_dcs_checked += 1

          pa_dc_reconciled = pa_distribution_centre.reconciled
          if pa_dc_reconciled == "false"
            count_pa_dcs_unreconciled += 1
            unreconciled_pa_distribution_centres.push(pa_distribution_centre)
          end
        end # each pa distribution centre

        puts "Komp Phenotype Attempt Distribution Centres checked      = #{count_pa_dcs_checked}"
        puts "Komp Phenotype Attempt Distribution Centres unreconciled = #{count_pa_dcs_unreconciled}"

        return unreconciled_pa_distribution_centres
      end # check on repository centre
    end

    #####
    # write results out to csv file
    #####
    def self.write_phenotype_attempt_results_to_csv( pa_results, output_pa_filepath )
      if ( pa_results && pa_results.length > 0 )
        # grab hash keys as sorted array
        sorted_pa_keys = pa_results.keys.sort

        # write results out to pa_filepath passed as attribute
        CSV.open(output_pa_filepath, "wb") do |csv|

          # write headers
          csv << ['marker_symbol', 'pa_attempt_dc_id', 'mi_plan_id', 'consortium', 'allele', 'exists_at_mmrrc', 'available_at_mmrrc' ]

          # iterate over sorted keys array and write csv lines
          sorted_pa_keys.each do |pa_key|
            marker_symbol = pa_key

            # might be more than one distribution centre for a phenotype attempt
            sorted_pa_dc_keys = pa_results[pa_key]['distribution_centres'].keys.sort

            sorted_pa_dc_keys.each do |pa_dc_key|
              pa_dc_id           = pa_dc_key
              dc_h               = pa_results[pa_key]['distribution_centres'][pa_dc_key]
              mi_plan_id         = dc_h['mi_plan_id']
              consortium         = dc_h['consortium']
              allele             = dc_h['allele']
              exists_at_mmrrc    = dc_h['exists_at_mmrrc']
              available_at_mmrrc = dc_h['available_at_mmrrc']

              # write row for each pa attempt distribution centre
              csv << [marker_symbol, pa_dc_id, mi_plan_id, consortium, allele, exists_at_mmrrc, available_at_mmrrc ]
            end # dcs
          end # pa
        end # csv
      end # if pa_results
    end

end # end class

if __FILE__ == $0
  # this will only run if the script was the main, not load'd or require'd
  CheckUnreconciledKompWithMmrrc.new( nil, nil ).check_komp_distribution_centres
end