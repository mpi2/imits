#!/usr/bin/env ruby

# to run, be in imits directory and run command:
# $ script/runner script/update_real_alleles.rb

require 'pp'

##
# This script checks all rows in various tables and connects them to real allele entries.
# It inserts new targ_rep_real_alleles as required.
# It checks foreign key links to the targ_rep_real_allele ids and updates them if necessary.
##

@sql_es_cells = "SELECT es.id AS es_id, al.gene_id AS es_gene_id, es.mgi_allele_symbol_superscript AS es_allele_name, "\
  "es.mgi_allele_id AS es_allele_mgi_accession_id, es.allele_symbol_superscript_template AS es_allele_name_template, "\
  "genes.mgi_accession_id AS es_gene_mgi_accession_id, mt.name AS es_mutation_name, "\
  "es.real_allele_id AS es_real_allele_id, ra.gene_id AS ra_gene_id, ra.allele_name AS ra_allele_name, "\
  "ra.allele_type AS ra_allele_type, ra.mgi_accession_id AS ra_allele_mgi_accession_id "\
  "FROM targ_rep_es_cells es JOIN targ_rep_alleles al ON al.id = es.allele_id "\
  "JOIN genes ON genes.id = al.gene_id JOIN targ_rep_mutation_types mt ON mt.id = al.mutation_type_id "\
  "LEFT OUTER JOIN targ_rep_real_alleles ra ON ra.id = es.real_allele_id ORDER BY es.id;"

@sql_mi_attempts = "SELECT mia.id AS mia_id, mias.name AS mia_status_name, mi_plans.gene_id AS mia_gene_id, "\
  "es.mgi_allele_symbol_superscript AS es_allele_name, es.mgi_allele_id AS es_allele_mgi_accession_id, "\
  "es.allele_symbol_superscript_template AS es_allele_name_template, "\
  "genes.mgi_accession_id AS mia_gene_mgi_accession_id, mia.mouse_allele_type AS mia_allele_type, "\
  "es.allele_type AS es_allele_type, es.real_allele_id AS es_real_allele_id, mia.real_allele_id AS mia_real_allele_id, "\
  "ra.gene_id AS ra_gene_id, ra.allele_name AS ra_allele_name, "\
  "ra.allele_type AS ra_allele_type, ra.mgi_accession_id AS ra_allele_mgi_accession_id, "\
  "al.cassette AS al_cassette, al.cassette_start AS al_cassette_start, al.cassette_end AS al_cassette_end, "\
  "al.loxp_start AS al_loxp_start, al.loxp_end AS al_loxp_end FROM mi_attempts mia "\
  "JOIN targ_rep_es_cells es ON es.id = mia.es_cell_id JOIN targ_rep_alleles al ON es.allele_id = al.id "\
  "JOIN mi_plans ON mi_plans.id = mia.mi_plan_id JOIN genes ON genes.id = mi_plans.gene_id "\
  "JOIN mi_attempt_statuses mias ON mias.id = mia.status_id "\
  "LEFT OUTER JOIN targ_rep_real_alleles ra ON ra.id = mia.real_allele_id ORDER BY mia.id;"

@sql_real_allele_id_where_match = "targ_rep_alleles.gene_id = ? AND targ_rep_alleles.cassette = ? "\
    "AND targ_rep_alleles.cassette_start =? AND targ_rep_alleles.cassette_end =? "\
    "AND targ_rep_alleles.loxp_start = ? AND targ_rep_alleles.loxp_end = ? "\
    "AND targ_rep_es_cells.mgi_allele_symbol_superscript = ? AND targ_rep_es_cells.real_allele_id IS NOT NULL"

@sql_phenotype_attempts = "SELECT pa.id AS pa_id, mi_plans.gene_id AS pa_gene_id, pa.allele_name AS pa_allele_name, "\
  "pa.mouse_allele_type AS pa_allele_type, pa.cre_excision_required AS pa_cre_excision_reqd, "\
  "mia.id AS mi_id, mia.mouse_allele_type AS mia_allele_type, "\
  "r.allele_type AS mia_ra_allele_type, es.allele_symbol_superscript_template AS es_allele_name_template, "\
  "pa.jax_mgi_accession_id AS pa_allele_mgi_accession_id, pa.status_id AS pa_status_id, pas.name AS pa_status_name, "\
  "pa.real_allele_id AS pa_real_allele_id, ra.gene_id AS ra_gene_id, ra.allele_name AS ra_allele_name, "\
  "ra.allele_type AS ra_allele_type, ra.mgi_accession_id AS ra_allele_mgi_accession_id "\
  "FROM phenotype_attempts pa JOIN mi_plans ON mi_plans.id = pa.mi_plan_id "\
  "JOIN phenotype_attempt_statuses pas ON pas.id = pa.status_id "\
  "JOIN mi_attempts mia ON mia.id = pa.mi_attempt_id "\
  "JOIN targ_rep_es_cells es ON es.id = mia.es_cell_id "\
  "LEFT OUTER JOIN targ_rep_real_alleles ra ON ra.id = pa.real_allele_id "\
  "LEFT OUTER JOIN targ_rep_real_alleles r ON r.id = mia.real_allele_id "\
  "ORDER BY pa.id;"

@sql_mouse_allele_mods = "SELECT mam.id AS mam_id, mi_plans.gene_id AS mam_gene_id, mam.allele_name AS mam_allele_name, "\
  "mam.mouse_allele_type AS mam_allele_type, mam.cre_excision AS mam_cre_excision_reqd, "\
  "mia.id AS mi_id, mia.mouse_allele_type AS mia_allele_type, "\
  "r.allele_type AS mia_ra_allele_type, es.allele_symbol_superscript_template AS es_allele_name_template, "\
  "mam.allele_mgi_accession_id AS mam_allele_mgi_accession_id, mam.status_id AS mam_status_id, mams.name AS mam_status_name, "\
  "mam.real_allele_id AS mam_real_allele_id, ra.gene_id AS ra_gene_id, ra.allele_name AS ra_allele_name, "\
  "ra.allele_type AS ra_allele_type, ra.mgi_accession_id AS ra_allele_mgi_accession_id "\
  "FROM mouse_allele_mods mam JOIN mi_plans ON mi_plans.id = mam.mi_plan_id "\
  "JOIN mouse_allele_mod_statuses mams ON mams.id = mam.status_id "\
  "JOIN mi_attempts mia ON mia.id = mam.mi_attempt_id "\
  "JOIN targ_rep_es_cells es ON es.id = mia.es_cell_id "\
  "LEFT OUTER JOIN targ_rep_real_alleles ra ON ra.id = mam.real_allele_id "\
  "LEFT OUTER JOIN targ_rep_real_alleles r ON r.id = mia.real_allele_id "\
  "ORDER BY mam.id;"

@sql_targeting_vectors = "WITH t1 AS ( SELECT targeting_vector_id, count(id) AS count_es_cells FROM targ_rep_es_cells "\
  "WHERE allele_type != 'e' GROUP BY targeting_vector_id ORDER BY targeting_vector_id ) "\
  "SELECT targ_rep_targeting_vectors.id AS tv_id, targ_rep_alleles.gene_id AS tv_gene_id, "\
  "genes.mgi_accession_id AS tv_mgi_accession_id, targ_rep_mutation_types.code AS tv_mutation_code, "\
  "t1.count_es_cells AS tv_count_es_cells, "\
  "targ_rep_targeting_vectors.mgi_allele_name_prediction AS tv_mgi_allele_name_prediction, "\
  "targ_rep_targeting_vectors.allele_type_prediction AS tv_allele_type_prediction "\
  "FROM targ_rep_targeting_vectors "\
  "JOIN targ_rep_alleles ON targ_rep_alleles.id = targ_rep_targeting_vectors.allele_id "\
  "JOIN genes ON genes.id = targ_rep_alleles.gene_id "\
  "JOIN targ_rep_mutation_types ON targ_rep_mutation_types.id = targ_rep_alleles.mutation_type_id "\
  "LEFT OUTER JOIN t1 ON t1.targeting_vector_id = targ_rep_targeting_vectors.id "\
  "ORDER BY targ_rep_targeting_vectors.id;"

@sql_select_unattached_real_allele_ids = \
  "SELECT targ_rep_real_alleles.id, targ_rep_real_alleles.gene_id, targ_rep_real_alleles.allele_name "\
  "FROM targ_rep_real_alleles "\
  "LEFT OUTER JOIN targ_rep_es_cells es  ON es.real_allele_id  = targ_rep_real_alleles.id "\
  "LEFT OUTER JOIN mi_attempts mia       ON mia.real_allele_id = targ_rep_real_alleles.id "\
  "LEFT OUTER JOIN phenotype_attempts pa ON pa.real_allele_id  = targ_rep_real_alleles.id "\
  "LEFT OUTER JOIN mouse_allele_mods mam ON mam.real_allele_id = targ_rep_real_alleles.id "\
  "WHERE es.real_allele_id IS NULL AND mia.real_allele_id IS NULL "\
  "AND pa.real_allele_id   IS NULL AND mam.real_allele_id IS NULL;"

@sql_select_real_allele_for_allele_name = "SELECT ra.gene_id AS ra_gene_id, es.allele_id AS es_allele_id, "\
  "ra.allele_name AS ra_allele_name, ra.allele_type AS ra_allele_type, ra.mgi_accession_id AS ra_allele_mgi_accession_id, "\
  "al.cassette AS al_cassette, al.cassette_start AS al_cassette_start, al.cassette_end AS al_cassette_end, "\
  "al.loxp_start AS al_loxp_start, al.loxp_end AS al_loxp_end "\
  "FROM targ_rep_real_alleles ra LEFT OUTER JOIN targ_rep_es_cells es ON es.real_allele_id = ra.id "\
  "LEFT OUTER JOIN targ_rep_alleles al ON es.allele_id = al.id WHERE ra.gene_id = ? AND ra.allele_name = ? "\
  "GROUP BY ra.gene_id, es.allele_id, ra.allele_name, ra.allele_type, ra.mgi_accession_id, "\
  "al.cassette, al.cassette_start, al.cassette_end, al.loxp_start, al.loxp_end;"

##
## Any initialisation before running checks
##
def initialise
  puts "initialise : start"

  @count_real_allele_inserts                         = 0
  @count_failed_real_allele_inserts                  = 0

  @count_es_cell_rows_checked                        = 0
  @count_es_cell_rows_missing_info                   = 0
  @count_es_cell_no_allele_name                      = 0
  @count_es_cell_rows_real_allele_match              = 0
  @count_es_cell_updates                             = 0
  @count_failed_es_cell_updates                      = 0

  @count_mi_attempt_rows_checked                     = 0
  @count_mi_attempt_rows_aborted                     = 0
  @count_mi_attempt_rows_missing_info                = 0
  @count_mi_attempt_es_cell_missing_real_allele_id   = 0
  @count_mi_attempt_rows_real_allele_match           = 0
  @count_mi_attempt_no_allele_name                   = 0
  @count_mi_attempt_no_es_cell_allele_to_compare     = 0
  @count_mi_attempt_no_cassette_info_match           = 0
  @count_mi_attempt_updates                          = 0
  @count_failed_mi_attempt_updates                   = 0

  @count_phenotype_attempt_rows_checked              = 0
  @count_phenotype_attempt_rows_missing_info         = 0
  @count_phenotype_attempt_rows_aborted              = 0
  @count_phenotype_attempt_rows_cre_excision_false   = 0
  @count_phenotype_attempt_rows_real_allele_match    = 0
  @count_phenotype_attempt_no_allele_name            = 0
  @count_phenotype_attempt_updates                   = 0
  @count_failed_phenotype_attempt_updates            = 0

  @count_mouse_allele_mod_rows_checked               = 0
  @count_mouse_allele_mod_rows_missing_info          = 0
  @count_mouse_allele_mod_rows_aborted               = 0
  @count_mouse_allele_mod_rows_cre_excision_false    = 0
  @count_mouse_allele_mod_rows_real_allele_match     = 0
  @count_mouse_allele_mod_no_allele_name             = 0
  @count_mouse_allele_mod_updates                    = 0
  @count_failed_mouse_allele_mod_updates             = 0

  @count_targeting_vector_rows_checked               = 0
  @count_targeting_vector_rows_missing_info          = 0
  @count_targeting_vector_rows_missing_mutation_code = 0
  @count_targeting_vector_rows_invalid_mutation_code = 0
  @count_targeting_vector_updates                    = 0
  @count_failed_targeting_vector_updates             = 0

  @count_deleted_unattached_real_alleles             = 0
  @count_failed_deletes_unattached_real_alleles      = 0

  puts "initialise : end"
end

##
## Check the targ_rep_es_cells table for new or updated real alleles
##
def check_targ_rep_es_cells
  puts "===== Checking targ_rep_es_cells table ====="

  results = ActiveRecord::Base.connection.execute(@sql_es_cells)

  results.each do |row|
    @count_es_cell_rows_checked += 1

    # TODO: if we skip the row do we want to actively update the real_allele_id to null??

    # check for missing key information
    if row['es_gene_id'].nil?
      @count_es_cell_rows_missing_info += 1
      next
    end

    display_es_cell_row_details( row )

    # check if row has an allele name or if not compose it
    allele_name = row['es_allele_name']
    if ( allele_name.nil? )
      # try to compose the allele name
      allele_name = compose_allele_name_for_es_cell ( row )
      if ( allele_name.nil? )
        puts "check_targ_rep_es_cells: WARN : unable to compose an allele name for row id #{row['es_id']}"
        @count_es_cell_no_allele_name += 1
        next
      end
    end

    # if row already has a real allele id, check whether its gene and allele name matches to the expected real allele name
    if ( ( ! row['es_real_allele_id'].nil? ) && ( row['es_real_allele_id'].to_i > 0 ) )
      if ( ( row['es_gene_id'] == row['ra_gene_id'] ) && ( allele_name == row['ra_allele_name'] ) )
        # current real allele matches expected, skip
        puts "check_targ_rep_es_cells : es cell row already has correct real allele id, skip as nothing to do"
        @count_es_cell_rows_real_allele_match += 1
        next
      end
    end

    # not a match, select or insert correct real allele and update
    new_real_allele_id = select_or_insert_real_allele( row['es_gene_id'], allele_name, row['es_allele_mgi_accession_id'] )

    # and update the row with the new real_allele_id
    if new_real_allele_id && new_real_allele_id > 0
      puts "check_targ_rep_es_cells: new real allele id = #{new_real_allele_id}"
      unless update_targ_rep_es_cell( row, new_real_allele_id )
        puts "check_targ_rep_es_cells : WARN : failed to update targ_rep_es_cells for id #{row['es_id']}"
      end
    else
      puts "check_targ_rep_es_cells : WARN : failed to fetch newly inserted real_allele_id, cannot update targ_rep_es_cells row for id #{row['es_id']}"
    end

  end
end

##
## Display es cell row details
##
def display_es_cell_row_details( row )
  puts "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  puts "check_targ_rep_es_cells : processing targ_rep_es_cell : "
  puts "es_id                      = #{row['es_id']}, "
  puts "es_gene_id                 = #{row['es_gene_id']}, "
  puts "es_allele_name             = #{row['es_allele_name']}, "
  puts "es_allele_mgi_accession_id = #{row['es_allele_mgi_accession_id']}, "
  puts "es_allele_name_template    = #{row['es_allele_name_template']}, "
  puts "es_gene_mgi_accession_id   = #{row['es_gene_mgi_accession_id']}, "
  puts "es_mutation_name           = #{row['es_mutation_name']}, "
  puts "es_real_allele_id          = #{row['es_real_allele_id']}, "
  puts "ra_gene_id                 = #{row['ra_gene_id']}, "
  puts "ra_allele_name             = #{row['ra_allele_name']}, "
  puts "ra_allele_type             = #{row['ra_allele_type']}, "
  puts "ra_allele_mgi_accession_id = #{row['ra_allele_mgi_accession_id']}"
  puts "- - - - - - - - - -"
  return
end

##
## Determine the expected allele name for this es cell row
##
def compose_allele_name_for_es_cell( row )

    allele_name = nil

    # use mutation type name to help determine allele name
    es_mutation_name = row['es_mutation_name']

    if ( ! es_mutation_name.nil? )
      allele_name = compose_allele_name_for_es_cell_mutation( es_mutation_name )
      if( allele_name.nil? )
        puts "compose_allele_name_for_es_cell : WARN : unable to create an allele name from the mutation name <#{es_mutation_name}>"
        return nil
      end
    else
      puts "compose_allele_name_for_es_cell : WARN : no es cell mutation name available"
      return nil
    end

    puts "compose_allele_name_for_es_cell : composed allele name = #{allele_name}"
    return allele_name
end

##
## Compose the allele name for an es cell using mutation type name
##
def compose_allele_name_for_es_cell_mutation ( es_mutation_name )

  case es_mutation_name
    when 'Conditional Ready'
      return 'tm1a'
    when 'Deletion'
      return 'tm1'
    when 'Targeted Non Conditional'
      return 'tm1e'
    when 'Cre Knock In'
      return 'tm1(Cre)'
    # when 'Cre BAC'
    #   return ''
    # when 'Insertion'
    #   return ''
    when 'Gene Trap'
      return 'gt'
    # when 'Point Mutation'
    #   return ''
    else
      puts "compose_allele_name_for_es_cell_mutation : WARN : es cell mutation type unrecognised"
      return nil
  end

end

##
## Check the mi_attempts table for new or updated real alleles
##
def check_mi_attempts
  puts "===== Checking mi_attempts table ====="

  results = ActiveRecord::Base.connection.execute(@sql_mi_attempts)

  results.each do |row|
    @count_mi_attempt_rows_checked += 1

    catch :next_mi_attempt do

      # TODO: if we skip the row do we want to actively update the real_allele_id to null??

      if is_mi_attempt_aborted?( row )
        throw :next_mi_attempt
      end

      if is_mi_attempt_missing_information?( row )
        throw :next_mi_attempt
      end

      display_mi_attempts_row_details( row )

      # if user has NOT overridden the allele type just look at the related es cell for the real allele id
      if row['mia_allele_type'].nil? || ( row['mia_allele_type'] == row['es_allele_type'] )
        # set real allele id to be same as that for the es cell if it exists
        if ( ! row['es_real_allele_id'].nil? ) && ( row['es_real_allele_id'].to_i > 0 )

          if is_mi_attempt_real_allele_id_match_existing?( row, row['es_real_allele_id'].to_i )
            throw :next_mi_attempt
          end

          # otherwise update row with es cell real allele id
          unless update_mi_attempt( row, row['es_real_allele_id'].to_i )
            puts "check_mi_attempts : WARN : failed to update mi_attempt for id #{row['mia_id']}"
          end
          throw :next_mi_attempt
        else
          # ES cell should have a real allele id from earlier part of script, count and skip
          puts "check_mi_attempts: WARN : related ES cell does not have a real allele id"
          @count_mi_attempt_es_cell_missing_real_allele_id += 1
          throw :next_mi_attempt
        end

      end

      # if user has overriden the allele type we need to modify the real allele id relative to its ES cell
      # this can happen when they make the mouse and get something different to that expected from the ES cell
      # e.g. ES cells supplied were a mixture of types and mouse germ line cells inherited from unexpected type
      if ! row['mia_allele_type'].nil?
        allele_name = compose_allele_name_for_mi_attempt( row )

        if ( allele_name.nil? )
          puts "check_mi_attempts: WARN : Failed to compose allele name from template for mi attempt id #{row['mia_id']}"
          @count_mi_attempt_no_allele_name += 1
          throw :next_mi_attempt
        end

        puts "check_mi_attempts: Created allele name from template = #{allele_name}"

        # search for matching es cells on es cell table for this gene and allele name
        es_real_allele_id = select_real_allele_id_for_matching_es_cell( row, allele_name )

        if ( ! es_real_allele_id.nil? ) && ( es_real_allele_id > 0 )

          if is_mi_attempt_real_allele_id_match_existing?( row, es_real_allele_id )
            throw :next_mi_attempt
          end

          # real allele id differs (perhaps due to user override of allele type) so update it
          unless update_mi_attempt( row, es_real_allele_id )
            puts "check_mi_attempts : WARN : failed to update mi_attempt for id = #{row['mia_id']}"
          end
          throw :next_mi_attempt
        else
          # no matching real allele amongst this genes ES cells, select or insert real allele
          puts "check_mi_attempts : select or insert real allele for gene id = #{row['mia_gene_id']} and allele_name = #{allele_name}"

          real_allele_id = select_or_insert_real_allele( row['mia_gene_id'], allele_name, row['es_allele_mgi_accession_id'] )

          # and update the mi attempt row with the new real_allele_id
          if real_allele_id && real_allele_id > 0
            puts "check_mi_attempts: new real allele id = #{real_allele_id}"

            if is_mi_attempt_real_allele_id_match_existing?( row, real_allele_id )
              throw :next_mi_attempt
            end

            unless update_mi_attempt( row, real_allele_id )
              puts "check_mi_attempts : WARN : failed to update mi_attempt for id #{row['mia_id']}"
            end
          else
            puts "check_mi_attempts : WARN : failed to fetch real_allele_id, cannot update mi_attempt row for id #{row['mia_id']}"
          end

          throw :next_mi_attempt
        end

      else
        puts "check_mi_attempts: WARN : Allele name template not present, cannot generate allele name"
        @count_mi_attempt_rows_missing_info += 1
        throw :next_mi_attempt
      end

    end # end catch next_mi_attempt
  end # loop mi attempt rows
  return
end

##
## Check for mi attempt aborted
##
def is_mi_attempt_aborted? ( row )
  if ( row['mia_status_name'] == 'Micro-injection aborted')
    @count_mi_attempt_rows_aborted += 1
    return true
  else
    return false
  end
end

##
## Check for missing key information
##
def is_mi_attempt_missing_information? ( row )
  if row['mia_gene_id'].nil?
    @count_mi_attempt_rows_missing_info += 1
    return true
  else
    return false
  end
end

##
## Check if mi attempt existing real allele id matches new real allele id
##
def is_mi_attempt_real_allele_id_match_existing?( row, new_real_allele_id )
  if ( ( ! row['mia_real_allele_id'].nil? ) && ( row['mia_real_allele_id'].to_i == new_real_allele_id ) )
    puts "check_mi_attempts : mi attempt row already has correct real allele id, skip as nothing to do"
    @count_mi_attempt_rows_real_allele_match += 1
    return true
  else
    return false
  end
end

##
## Display mi attempt row details
##
def display_mi_attempts_row_details ( row )
  puts "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  puts "check_mi_attempts : processing mi attempt : "
  puts "mia_id                     = #{row['mia_id']}, "
  puts "mia_status_name            = #{row['mia_status_name']}, "
  puts "mia_gene_id                = #{row['mia_gene_id']}, "
  puts "es_allele_name             = #{row['es_allele_name']}, "
  puts "es_allele_mgi_accession_id = #{row['es_allele_mgi_accession_id']}, "
  puts "es_allele_name_template    = #{row['es_allele_name_template']}, "
  puts "mia_gene_mgi_accession_id  = #{row['mia_gene_mgi_accession_id']}, "
  puts "mia_allele_type            = #{row['mia_allele_type']}, "
  puts "es_allele_type             = #{row['es_allele_type']}, "
  puts "es_real_allele_id          = #{row['es_real_allele_id']}, "
  puts "mia_real_allele_id         = #{row['mia_real_allele_id']}, "
  puts "ra_gene_id                 = #{row['ra_gene_id']}, "
  puts "ra_allele_name             = #{row['ra_allele_name']}, "
  puts "ra_allele_type             = #{row['ra_allele_type']}, "
  puts "ra_allele_mgi_accession_id = #{row['ra_allele_mgi_accession_id']}, "
  puts "al_cassette                = #{row['al_cassette']}, "
  puts "al_cassette_start          = #{row['al_cassette_start']}, "
  puts "al_cassette_end            = #{row['al_cassette_end']}, "
  puts "al_loxp_start              = #{row['al_loxp_start']}, "
  puts "al_loxp_end                = #{row['al_loxp_end']}"
  puts "- - - - - - - - - -"
  return
end

##
## Determine the expected allele name for this mi attempt row
##
def compose_allele_name_for_mi_attempt( row )
  # create a new allele name using template
  es_allele_name_template = row['es_allele_name_template']

  if es_allele_name_template.nil?
    puts "compose_allele_name_for_mi_attempt : No ES cell allele name template found"
    return nil
  end

  # use es cell template to generate the allele name
  allele_name = es_allele_name_template.sub!('@', row['mia_allele_type'])

  puts "compose_allele_name_for_mi_attempt : composed allele name from template = #{allele_name}"

  # possible this new allele name already in use for this gene with another vector (i.e. different cassette details)
  # select on gene, allele name exists from real allele table as es cells have been done first
  begin
    exist_ra = TargRep::RealAllele.find_by_sql( [ @sql_select_real_allele_for_allele_name, row['mia_gene_id'], allele_name ] ).first
    if ( exist_ra.nil? )
      # allele name is new and Ok to use it
      puts "compose_allele_name_for_mi_attempt : no match found, allele name is new and can be used"
      return allele_name
    else
      puts "compose_allele_name_for_mi_attempt : found real allele matching name, checking cassette information for match"

      if exist_ra['es_allele_id'].nil?
        # no es cell allele to check
        puts "compose_allele_name_for_mi_attempt : no es cell allele to compare with"
        @count_mi_attempt_no_es_cell_allele_to_compare += 1
        return allele_name
      else
        puts "- - cassette information : - -"
        puts "al_cassette           = #{exist_ra['al_cassette']}, "
        puts "al_cassette_start     = #{exist_ra['al_cassette_start']}, "
        puts "al_cassette_end       = #{exist_ra['al_cassette_end']}"
        puts "- - - -"

        # compare the cassette information to that of the mi attempt's allele
        if ( exist_ra['al_cassette']            == row['al_cassette'] \
          && exist_ra['al_cassette_start'].to_i == row['al_cassette_start'].to_i \
          && exist_ra['al_cassette_end'].to_i   == row['al_cassette_end'].to_i )

          # match so use this allele name
          puts "compose_allele_name_for_mi_attempt : cassette information matches"
          return allele_name
        else
          #   if not same -> loop on tm number until find match?
          puts "compose_allele_name_for_mi_attempt : cassette information does not match"
          @count_mi_attempt_no_cassette_info_match += 1
          return nil
        end
      end

    end
  rescue => e
    puts "compose_allele_name_for_mi_attempt : WARN : failed to compose allele name for mi_attempt with id #{row['mia_id']}"
    puts "compose_allele_name_for_mi_attempt : message : #{e.message}"
    return nil
  end

end

##
## Select the real allele id for this gene where the allele cassette details match and it has this modified allele name
##
def select_real_allele_id_for_matching_es_cell( row, allele_name )

  puts "select_real_allele_id_for_matching_es_cell : for : gene_id = #{row['mia_gene_id']} and allele_name = #{allele_name}"

  es_cell = TargRep::EsCell.joins(:allele).where(@sql_real_allele_id_where_match, \
    row['mia_gene_id'], \
    row['al_cassette'], \
    row['al_cassette_start'], \
    row['al_cassette_end'], \
    row['al_loxp_start'], \
    row['al_loxp_end'], \
    allele_name ).group(:real_allele_id).select("targ_rep_es_cells.real_allele_id").first

  unless es_cell.nil?
    real_allele_id = es_cell['real_allele_id'].to_i
    if real_allele_id > 0
      puts "select_real_allele_id_for_matching_es_cell : identified match in ES cell real allele id = #{real_allele_id}"
      return real_allele_id
    end
  end

  # no matching es cell found
  return nil
end

##
## Check the phenotype_attempts table for new or updated real alleles
##
def check_phenotype_attempts
  puts "===== Checking phenotype_attempts table ====="

  results = ActiveRecord::Base.connection.execute(@sql_phenotype_attempts)

  results.each do |row|
    @count_phenotype_attempt_rows_checked += 1

    catch :next_phenotype_attempt do

      # TODO: if we skip the row do we want to actively update the real_allele_id to null in all cases?

      if is_phenotype_attempt_aborted?( row )
        throw :next_phenotype_attempt
      end

      if is_phenotype_attempt_missing_information?( row )
        throw :next_phenotype_attempt
      end

      # check cre_excision_required flag
      if ( row['pa_cre_excision_reqd'] == 'f' )
        @count_phenotype_attempt_rows_cre_excision_false += 1
        if ( ( ! row['pa_real_allele_id'].nil? ) && ( row['pa_real_allele_id'].to_i > 0 ) )
          # set real allele id back to null for this row (to trap when user has changed flag to false)
          puts "check_phenotype_attempts : Setting real allele id to null for phenotype attempt with id #{row['pa_id']}"
          unless update_phenotype_attempt( row, nil )
            puts "check_phenotype_attempts : WARN : failed to update phenotype_attempt to nil for id #{row['pa_id']}"
          end
        end
        throw :next_phenotype_attempt
      end

      display_phenotype_attempt_row_details( row )

      # check if row has an allele name or if not compose it
      allele_name = row['pa_allele_name']
      if ( allele_name.nil? )
        # try to compose the allele name
        allele_name = compose_allele_name_for_phenotype_attempt ( row )
        if ( allele_name.nil? )
          puts "check_phenotype_attempts: WARN : unable to compose an allele name for row id #{row['pa_id']}"
          @count_phenotype_attempt_no_allele_name += 1
          throw :next_phenotype_attempt
        end
      end

      puts "check_phenotype_attempts: Created allele name = #{allele_name}"

      new_real_allele_id = select_or_insert_real_allele( row['pa_gene_id'], allele_name, row['pa_allele_mgi_accession_id'] )

      # check whether we need to update the row
      if ( new_real_allele_id && new_real_allele_id > 0 )
        puts "check_phenotype_attempts: new real allele id = #{new_real_allele_id}"

        if is_phenotype_attempt_real_allele_id_matching_existing?( row, new_real_allele_id )
          puts "check_phenotype_attempts : phenotype attempt row already has correct real allele id, skip as nothing to do"
          throw :next_phenotype_attempt
        end

        unless update_phenotype_attempt( row, new_real_allele_id )
          puts "check_phenotype_attempts : WARN : failed to update phenotype_attempt for id #{row['pa_id']}"
          throw :next_phenotype_attempt
        end
      else
        puts "check_phenotype_attempts : ERROR : failed to fetch newly inserted real_allele_id, cannot update phenotype_attempt row for id #{row['pa_id']}"
        @count_failed_phenotype_attempt_updates += 1
        throw :next_phenotype_attempt
      end

    end # catch next phenotype attempt
  end # next row
  return
end

##
## Check for phenotype attempt aborted
##
def is_phenotype_attempt_aborted?( row )
  if ( row['pa_status_name'] == 'Phenotype Attempt Aborted' )
    @count_phenotype_attempt_rows_aborted += 1
    return true
  else
    return false
  end
end

##
## Check for missing key information
##
def is_phenotype_attempt_missing_information?( row )
  if row['pa_gene_id'].nil?
    @count_phenotype_attempt_rows_missing_info += 1
    return true
  else
    return false
  end
end

##
## Check if phenotype attempt existing real allele id matches new real allele id
##
def is_phenotype_attempt_real_allele_id_matching_existing?( row, new_real_allele_id )
  if ( ( ! row['pa_real_allele_id'].nil? ) && ( row['pa_real_allele_id'].to_i == new_real_allele_id ) )
    @count_phenotype_attempt_rows_real_allele_match += 1
    return true
  else
    return false
  end
end

##
## Display the phenotype attempts row details
##
def display_phenotype_attempt_row_details( row )
  puts "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  puts "check_phenotype_attempts : processing phenotype_attempts "
  puts "pa_id = #{row['pa_id']}, "
  puts "pa_gene_id = #{row['pa_gene_id']}, "
  puts "pa_allele_name = #{row['pa_allele_name']}, "
  puts "pa_allele_type = #{row['pa_allele_type']}, "
  puts "pa_cre_excision_reqd = #{row['pa_cre_excision_reqd']}, "
  puts "mi_id = #{row['mi_id']}, "
  puts "mia_allele_type = #{row['mia_allele_type']}, "
  puts "mia_ra_allele_type = #{row['mia_ra_allele_type']}, "
  puts "es_allele_name_template = #{row['es_allele_name_template']}, "
  puts "pa_allele_mgi_accession_id = #{row['pa_allele_mgi_accession_id']}, "
  puts "pa_status_id = #{row['pa_status_id']}, "
  puts "pa_status_name = #{row['pa_status_name']}, "
  puts "pa_real_allele_id = #{row['pa_real_allele_id']}, "
  puts "ra_gene_id = #{row['ra_gene_id']}, "
  puts "ra_allele_name = #{row['ra_allele_name']}, "
  puts "ra_allele_type = #{row['ra_allele_type']}, "
  puts "ra_allele_mgi_accession_id = #{row['ra_allele_mgi_accession_id']}"
  puts "- - - - - - - - - -"
  return
end

##
## Determine the expected allele name for this phenotype attempt row
##
def compose_allele_name_for_phenotype_attempt( row )

    es_allele_name_template = row['es_allele_name_template']
    if es_allele_name_template.nil?
      puts "compose_allele_name_for_phenotype_attempt : No ES cell allele name template available"
      return nil
    end

    allele_type = compose_allele_type( row['pa_allele_type'], row['mia_ra_allele_type'] )

    if allele_type.nil?
      puts "compose_allele_name_for_phenotype_attempt : WARN : no allele type available to create allele name"
      return nil
    end

    allele_name = es_allele_name_template.sub!('@', allele_type)
    puts "compose_allele_name_for_phenotype_attempt : composed allele name = #{allele_name}"

    return allele_name
end

##
## Compose the allele type from the override or mi attempt allele types
##
def compose_allele_type( override_allele_type, mi_attempt_allele_type )

  if ( ! override_allele_type.nil? ) && ( ['a','b','c','d','e','e.1','.1','.2', ''].include?( override_allele_type ) )
    puts "compose_allele_type : using override real allele type"
    return override_allele_type
  else
    # use real allele type from mi attempt to map to new allele type
    if ( ! mi_attempt_allele_type.nil? )
      puts "compose_allele_type : no valid override, attempting to use mi attempt real allele type"
      case mi_attempt_allele_type
        when 'a'
          return 'b'
        when ''
          return '.1'
        when 'e'
          return 'e.1'
        else
          puts "compose_allele_type : WARN : mi attempt allele type unrecognised"
          return nil
      end
    else
      # cannot determine allele type
      puts "compose_allele_type : WARN : no valid override and no mi attempt allele types available"
      return nil
    end
  end
end

##
## Check the mouse_allele_mods table for new or updated real alleles
##
def check_mouse_allele_mods
  puts "===== Checking mouse_allele_mods table ====="

  results = ActiveRecord::Base.connection.execute(@sql_mouse_allele_mods)

  results.each do |row|
    @count_mouse_allele_mod_rows_checked += 1

    catch :next_mouse_allele_mod do

      # TODO: if we skip the row do we want to actively update the real_allele_id to null in all cases?

      if is_mouse_allele_mod_aborted?( row )
        throw :next_mouse_allele_mod
      end

      if is_mouse_allele_mod_missing_information?( row )
        throw :next_mouse_allele_mod
      end

      # check cre_excision_required flag
      if ( row['mam_cre_excision_reqd'] == 'f' )
        @count_mouse_allele_mod_rows_cre_excision_false += 1
        if ( ( ! row['mam_real_allele_id'].nil? ) && ( row['mam_real_allele_id'].to_i > 0 ) )
          # set real allele id back to null for this row (to trap when user has changed flag to false)
          unless update_mouse_allele_mod( row, nil )
            puts "check_mouse_allele_mods : WARN : failed to update mouse_allele_mod to nil for id #{row['mam_id']}"
          end
        end
        throw :next_mouse_allele_mod
      end

      display_mouse_allele_mod_row_details( row )

      # check if row has an allele name or if not compose it
      allele_name = row['mam_allele_name']
      if ( allele_name.nil? )
        # try to compose the allele name
        allele_name = compose_allele_name_for_mouse_allele_mod ( row )
        if ( allele_name.nil? )
          puts "check_mouse_allele_mods: WARN : unable to compose an allele name for row id #{row['mam_id']}"
          @count_mouse_allele_mod_no_allele_name += 1
          throw :next_mouse_allele_mod
        end
      end

      puts "check_mouse_allele_mods: Created allele name = #{allele_name}"

      new_real_allele_id = select_or_insert_real_allele( row['mam_gene_id'], allele_name, row['mam_allele_mgi_accession_id'] )

      # check whether we need to update the row
      if new_real_allele_id && new_real_allele_id > 0
        puts "check_mouse_allele_mods: new real allele id = #{new_real_allele_id}"

        if is_mouse_allele_mod_real_allele_id_matching_existing?( row, new_real_allele_id )
          puts "check_mouse_allele_mods : mouse allele mod row already has correct real allele id, skip as nothing to do"
          throw :next_mouse_allele_mod
        end

        unless update_mouse_allele_mod( row, new_real_allele_id )
          puts "check_mouse_allele_mods : WARN : failed to update mouse_allele_mod for id #{row['mam_id']}"
        end
      else
        puts "check_mouse_allele_mods : ERROR: failed to fetch newly inserted real_allele_id, cannot update mouse_allele_mod row for id #{row['mam_id']}"
        @count_failed_mouse_allele_mod_updates += 1
      end

    end # catch next row
  end # next row
  return
end

##
## Check for mouse allele mod aborted
##
def is_mouse_allele_mod_aborted?( row )
  if ( row['mam_status_name'] == 'Mouse Allele Modification Aborted' )
    @count_mouse_allele_mod_rows_aborted += 1
    return true
  else
    return false
  end
end

##
## Check for missing key information
##
def is_mouse_allele_mod_missing_information?( row )
  if row['mam_gene_id'].nil?
    @count_mouse_allele_mod_rows_missing_info += 1
    return true
  else
    return false
  end
end

##
## Check if mouse allele mod existing real allele id matches new real allele id
##
def is_mouse_allele_mod_real_allele_id_matching_existing?( row, new_real_allele_id )
  if ( ( ! row['mam_real_allele_id'].nil? ) && ( row['mam_real_allele_id'].to_i == new_real_allele_id ) )
    @count_mouse_allele_mod_rows_real_allele_match += 1
    return true
  else
    return false
  end
end

##
## Display the Mouse Allele Mods row details
##
def display_mouse_allele_mod_row_details( row )
  puts "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  puts "check_mouse_allele_mods : processing mouse_allele_mods "
  puts "mam_id = #{row['mam_id']}, "
  puts "mam_gene_id = #{row['mam_gene_id']}, "
  puts "mam_allele_name = #{row['mam_allele_name']}, "
  puts "mam_allele_type = #{row['mam_allele_type']}, "
  puts "mam_cre_excision_reqd = #{row['mam_cre_excision_reqd']}, "
  puts "mi_id = #{row['mi_id']}, "
  puts "mia_allele_type = #{row['mia_allele_type']}, "
  puts "mia_ra_allele_type = #{row['mia_ra_allele_type']}, "
  puts "es_allele_name_template = #{row['es_allele_name_template']}, "
  puts "mam_allele_mgi_accession_id = #{row['mam_allele_mgi_accession_id']}, "
  puts "mam_status_id = #{row['mam_status_id']}, "
  puts "mam_status_name = #{row['mam_status_name']}, "
  puts "mam_real_allele_id = #{row['mam_real_allele_id']}, "
  puts "ra_gene_id = #{row['ra_gene_id']}, "
  puts "ra_allele_name = #{row['ra_allele_name']}, "
  puts "ra_allele_type = #{row['ra_allele_type']}, "
  puts "ra_allele_mgi_accession_id = #{row['ra_allele_mgi_accession_id']}"
  puts "- - - - - - - - - -"
  return
end

##
## Determine the expected allele name for this Mouse Allele Mod row
##
def compose_allele_name_for_mouse_allele_mod( row )

    es_allele_name_template = row['es_allele_name_template']
    if es_allele_name_template.nil?
      puts "compose_allele_name_for_mouse_allele_mod : No ES cell allele name template available"
      return nil
    end

    allele_type = compose_allele_type( row['mam_allele_type'], row['mia_ra_allele_type'] )

    if allele_type.nil?
      puts "compose_allele_name_for_mouse_allele_mod : WARN : no allele type available to create allele name"
      return nil
    end

    allele_name = es_allele_name_template.sub!('@', allele_type)
    puts "compose_allele_name_for_mouse_allele_mod : composed allele name = #{allele_name}"

    return allele_name
end

##
## Check the targ_rep_targeting_alleles table for new or updated real alleles
##
def check_targ_rep_targeting_vectors
  puts "===== Checking targ_rep_targeting_vectors table ====="

  results = ActiveRecord::Base.connection.execute(@sql_targeting_vectors)

  results.each do |row|
    @count_targeting_vector_rows_checked += 1

    catch :next_targeting_vector do

      # TODO: if we skip the row do we want to actively update the real_allele_id to null??

      if is_targeting_vector_row_missing_information?( row )
        throw :next_targeting_vector
      end

      if is_targeting_vector_mutation_code_invalid?( row )
        throw :next_targeting_vector
      end

      display_targeting_vector_row_details( row )

      new_allele_name = nil
      new_allele_type = nil

      if ( ! row['tv_count_es_cells'].nil? && row['tv_count_es_cells'].to_i > 0 )
        # have es cells so use one to determine allele name and type
        puts "SELECT an es cell"
        es_cell = select_es_cell_for_targeting_vector(row['tv_id'])

        if es_cell.nil?
          puts "check_targ_rep_targeting_vectors : ERROR: Failed to select es cell, skipping row"
          @count_failed_targeting_vector_updates += 1
          throw :next_targeting_vector
        else
          new_allele_name = es_cell.mgi_allele_symbol_superscript
          new_allele_type = es_cell.allele_type
        end
      else
        # if no es cells use allele mutation code to work out allele type
        new_allele_name, new_allele_type = derive_allele_details_from_mutation_type( row['tv_mutation_code'] )

        # allele type can be an empty string but not nil
        if ( new_allele_name.nil? || new_allele_type.nil? )
          puts "check_targ_rep_targeting_vectors : WARN : Mutation code <#{row['tv_mutation_code']}> unrecognised, skipping row"
          @count_failed_targeting_vector_updates += 1
          throw :next_targeting_vector
        end
      end

      puts "check_targ_rep_targeting_vectors : new_allele_type = #{new_allele_type} and new_allele_name = #{new_allele_name}"

      # if allele_type_prediction or mgi_allele_name_prediction not same update them
      if ( ( row['tv_mgi_allele_name_prediction'] != new_allele_name ) || ( row['tv_allele_type_prediction'] != new_allele_type ) )
        unless update_targ_rep_targeting_vector( row, new_allele_name, new_allele_type )
          puts "check_targ_rep_targeting_vectors : WARN : failed to update targeting vector id #{row['tv_id']}"
        end
      end
    end # catch next row
  end # each row

  return
end

##
## Check for missing key information
##
def is_targeting_vector_row_missing_information?( row )
  if row['tv_gene_id'].nil?
    @count_targeting_vector_rows_missing_info += 1
    return true
  else
    return false
  end
end

##
## Check mutation type
##
def is_targeting_vector_mutation_code_invalid?( row )
  if row['tv_mutation_code'].nil?
    @count_targeting_vector_rows_missing_mutation_code += 1
    return true
  end

  unless  ["crd", "del", "cki"].include?( row['tv_mutation_code'] )
    puts "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
    puts "is_targeting_vector_mutation_code_valid : invalid mutation code <#{row['tv_mutation_code']}> "\
         "for targ_rep_targeting_vectors id = #{row['tv_id']}, gene_id = #{row['tv_gene_id']}, "\
         "mutation_code = #{row['tv_mutation_code']}, mgi_accession_id = #{row['tv_mgi_accession_id']}"
    @count_targeting_vector_rows_invalid_mutation_code += 1
    return true
  end

  return false
end

##
## Display the Targeting vector row details
##
def display_targeting_vector_row_details( row )
  puts "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  puts "display_targeting_vector_row_details : processing targ_rep_targeting_vectors "
  puts "id = #{row['tv_id']}, "
  puts "gene_id = #{row['tv_gene_id']}, "
  puts "mutation_code = #{row['tv_mutation_code']}, "
  puts "mgi_accession_id = #{row['tv_mgi_accession_id']}, "
  puts "mgi_allele_name_prediction = #{row['tv_mgi_allele_name_prediction']}, "
  puts "allele_type_prediction = #{row['tv_allele_type_prediction']}, "
  puts "count es cells = #{row['tv_count_es_cells']}"
  puts "- - - - - - - - - -"
  return
end

##
## Derive the allele name and type from the mutation type
##
def derive_allele_details_from_mutation_type( mutation_code )

  case mutation_code
    when 'crd'
      # Conditional Ready
      return 'tm1a', 'a'
    when 'del'
      # Deletion
      return 'tml1', ''
    when 'tnc'
      # Targeted Non Conditional
      return 'tm1e', 'e'
    when 'cki'
      # Cre Knock In
      return 'tm1(CRE)', ''
    when 'gt'
      # Gene Trap
      return 'genetrap', 'gt'
    # when 'cbc'
    #   # Cre BAC
    #   return '?', '?'
    # when 'ins'
    #   # Insertion
    #   return '?', '?'
    # when 'pnt'
    #   # Point mutation
    #   return '?','?'
    else
      puts "derive_allele_detail_from_mutation_type : WARN : Mutation code unrecognised"
      return nil, nil
  end
end

##
## Any post-run cleanup in here
##
def cleanup
  # remove unattached real alleles from the database (e.g. guesses no longer needed)
  delele_unattached_real_alleles()
  display_counters()
  return
end

##
## Delete unattached real alleles
##
def delele_unattached_real_alleles

  real_alleles_to_delete = TargRep::RealAllele.find_by_sql(@sql_select_unattached_real_allele_ids)

  puts "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"

  if real_alleles_to_delete.nil? || real_alleles_to_delete.count == 0
    puts "delele_unattached_real_alleles : no unattached real alleles to delete"
  else
    begin
      puts "delele_unattached_real_alleles : deleting unattached real alleles : "
      real_alleles_to_delete.each do |real_allele|
        puts "delele_unattached_real_alleles : deleting real_allele id = #{real_allele.id}, gene_id = #{real_allele.gene_id}, allele_name = #{real_allele.allele_name}"
        TargRep::RealAllele.delete(real_allele.id)
        @count_deleted_unattached_real_alleles += 1
      end
    rescue => e
      puts "delele_unattached_real_alleles : ERROR : failed to delete unattached real alleles"
      puts "delele_unattached_real_alleles : message : #{e.message}"
      @count_failed_deletes_unattached_real_alleles += 1
    end
  end

  puts "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  return
end

##
## Display the counter totals
##
def display_counters

  puts "Counters:"
  puts "---------"
  puts "Table: real_alleles"
  puts "real allele inserts                            = #{@count_real_allele_inserts}"
  puts ""
  puts "Table: targ_rep_es_cells"
  puts "rows checked                                   = #{@count_es_cell_rows_checked}"
  puts "rows skipped as missing info                   = #{@count_es_cell_rows_missing_info}"
  puts "rows skipped as no allele name                 = #{@count_es_cell_no_allele_name}"
  puts "rows skipped as allele id match                = #{@count_es_cell_rows_real_allele_match}"
  puts "updates                                        = #{@count_es_cell_updates}"
  puts ""
  puts "Table: mi_attempts"
  puts "rows checked                                   = #{@count_mi_attempt_rows_checked}"
  puts "rows skipped as missing info                   = #{@count_mi_attempt_rows_missing_info}"
  puts "rows skipped as aborted                        = #{@count_mi_attempt_rows_aborted}"
  puts "rows skipped as missing ES cell real allele id = #{@count_mi_attempt_es_cell_missing_real_allele_id}"
  puts "rows skipped as allele id match                = #{@count_mi_attempt_rows_real_allele_match}"
  puts "rows skipped as no allele name                 = #{@count_mi_attempt_no_allele_name}"
  puts "rows skipped as no es cell allele to compare   = #{@count_mi_attempt_no_es_cell_allele_to_compare}"
  puts "rows unmatched cassette info                   = #{@count_mi_attempt_no_cassette_info_match}"
  puts "updates                                        = #{@count_mi_attempt_updates}"
  puts ""
  puts "Table: phenotype_attempts"
  puts "rows checked                                   = #{@count_phenotype_attempt_rows_checked}"
  puts "rows skipped as missing info                   = #{@count_phenotype_attempt_rows_missing_info}"
  puts "rows skipped as aborted                        = #{@count_phenotype_attempt_rows_aborted}"
  puts "rows skipped as cre excision false             = #{@count_phenotype_attempt_rows_cre_excision_false}"
  puts "rows skipped as allele id match                = #{@count_phenotype_attempt_rows_real_allele_match}"
  puts "rows skipped as no allele name                 = #{@count_phenotype_attempt_no_allele_name}"
  puts "updates                                        = #{@count_phenotype_attempt_updates}"
  puts ""
  puts "Table: mouse_allele_mods"
  puts "rows checked                                   = #{@count_mouse_allele_mod_rows_checked}"
  puts "rows skipped as missing info                   = #{@count_mouse_allele_mod_rows_missing_info}"
  puts "rows skipped as aborted                        = #{@count_mouse_allele_mod_rows_aborted}"
  puts "rows skipped as cre excision false             = #{@count_mouse_allele_mod_rows_cre_excision_false}"
  puts "rows skipped as allele id match                = #{@count_mouse_allele_mod_rows_real_allele_match}"
  puts "rows skipped as no allele name                 = #{@count_mouse_allele_mod_no_allele_name}"
  puts "updates                                        = #{@count_mouse_allele_mod_updates}"
  puts ""
  puts "Table: targ_rep_targeting_vectors"
  puts "rows checked                                   = #{@count_targeting_vector_rows_checked}"
  puts "rows skipped as missing info                   = #{@count_targeting_vector_rows_missing_info}"
  puts "rows skipped as missing mutation code          = #{@count_targeting_vector_rows_missing_mutation_code}"
  puts "rows skipped as mutation code is invalid       = #{@count_targeting_vector_rows_invalid_mutation_code}"
  puts "updates                                        = #{@count_targeting_vector_updates}"
  puts ""
  puts "Deleted unattached real alleles                = #{@count_deleted_unattached_real_alleles}"
  puts ""
  puts "FAILURES:"
  puts "FAILED real allele inserts                     = #{@count_failed_real_allele_inserts}"
  puts "FAILED targ rep es cell updates                = #{@count_failed_es_cell_updates}"
  puts "FAILED mi attempt updates                      = #{@count_failed_mi_attempt_updates}"
  puts "FAILED phenotype attempt updates               = #{@count_failed_phenotype_attempt_updates}"
  puts "FAILED mouse allele mod updates                = #{@count_failed_mouse_allele_mod_updates}"
  puts "FAILED targ rep targeting vector updates       = #{@count_failed_targeting_vector_updates}"
  puts "FAILED deletes of unattached real alleles      = #{@count_failed_deletes_unattached_real_alleles}"

  return
end

##
## Update the real allele id in the targ_rep_es_cells table
##
def update_targ_rep_es_cell ( row, real_allele_id )
  puts "update_targ_rep_es_cell : id = #{row['es_id']}, real_allele_id = #{real_allele_id}"

  es_cell = TargRep::EsCell.find( row['es_id'] )

  if es_cell.nil?
    puts "update_targ_rep_es_cell : ERROR updating es cell with id #{row['es_id']}, no es cell found"
    @count_failed_targ_rep_es_cell_updates += 1
    return false
  end

  begin
    es_cell.real_allele_id = real_allele_id
    es_cell.save!
    @count_es_cell_updates += 1
    return true
  rescue => e
    puts "update_targ_rep_es_cell : ERROR updating es_cell with id #{row['es_id']}"
    puts "update_targ_rep_es_cell : message : #{e.message}"
    @count_failed_es_cell_updates += 1
    return false
  end

end

##
## Update the real allele id in the mi_attempts table
##
def update_mi_attempt ( row, real_allele_id )
  puts "update_mi_attempt : updating mi attempt id = #{row['mia_id']}, current real allele id = #{row['mia_real_allele_id']}, new real_allele_id = #{real_allele_id}"
  # puts "update_mi_attempt : mi attempt id = #{mi_attempt_id}, new real_allele_id = #{real_allele_id}"

  mi_attempt = Public::MiAttempt.find( row['mia_id'] )

  if mi_attempt.nil?
    puts "update_mi_attempt : ERROR updating mi attempt with id #{row['mia_id']}, no mi attempt found"
    @count_failed_mi_attempt_updates += 1
    return false
  end

  begin
    mi_attempt.real_allele_id = real_allele_id
    mi_attempt.save!
    @count_mi_attempt_updates += 1
    return true
  rescue => e
    puts "update_mi_attempt : ERROR updating mi_attempt with id #{row['mia_id']}"
    puts "update_mi_attempt : message : #{e.message}"
    @count_failed_mi_attempt_updates += 1
    return false
  end
end

##
## Update the real allele id in the phenotype_attempts table
##
def update_phenotype_attempt ( row, real_allele_id )
  puts "update_phenotype_attempt : id = #{row['pa_id']}, new real_allele_id = #{real_allele_id}"

  phenotype_attempt = Public::PhenotypeAttempt.find( row['pa_id'] )

  if phenotype_attempt.nil?
    puts "update_phenotype_attempt : ERROR updating phenotype attempt with id #{row['pa_id']}, no phenotype attempt found"
    @count_failed_phenotype_attempt_updates += 1
    return false
  end

  begin
    phenotype_attempt.real_allele_id = real_allele_id
    phenotype_attempt.save!
    @count_phenotype_attempt_updates += 1
    return true
  rescue => e
    puts "update_phenotype_attempt : ERROR updating phenotype_attempt with id #{row['pa_id']}"
    puts "update_phenotype_attempt : message : #{e.message}"
    @count_failed_phenotype_attempt_updates += 1
    return false
  end
end

##
## Update the real allele id in the mouse_allele_mods table
##
def update_mouse_allele_mod ( row, real_allele_id )
  puts "update_mouse_allele_mod : id = #{row['mam_id']}, real_allele_id = #{real_allele_id}"

  mouse_allele_mod = MouseAlleleMod.find( row['mam_id'] )

  if mouse_allele_mod.nil?
    puts "update_mouse_allele_mod : ERROR updating mouse allele mod with id #{row['mam_id']}, no mouse allele mod found"
    @count_failed_mouse_allele_mod_updates += 1
    return false
  end

  begin
    mouse_allele_mod.real_allele_id = real_allele_id
    mouse_allele_mod.save!
    @count_mouse_allele_mod_updates += 1
    return true
  rescue => e
    puts "update_mouse_allele_mod : ERROR updating mouse_allele_mod with id #{row['mam_id']}"
    puts "update_mouse_allele_mod : message : #{e.message}"
    @count_failed_mouse_allele_mod_updates += 1
    return false
  end
end

##
## Update the mgi_allele_name_prediction and allele_type_prediction in the targ_rep_targeting_vectors table
##
def update_targ_rep_targeting_vector ( row, mgi_allele_name_prediction, allele_type_prediction )
  puts "update_targ_rep_targeting_vector : id = #{row['tv_id']}, mgi_allele_name_prediction = #{mgi_allele_name_prediction}, "\
    "allele_type_prediction = #{allele_type_prediction}"

  targ_rep_targeting_vector = TargRep::TargetingVector.find( row['tv_id'] )

  if targ_rep_targeting_vector.nil?
    puts "update_targ_rep_targeting_vector : ERROR updating targeting_vector with id #{row['tv_id']}, no targeting_vector found"
    @count_failed_targeting_vector_updates += 1
    return false
  end

  begin
    targ_rep_targeting_vector.allele_type_prediction     = allele_type_prediction
    targ_rep_targeting_vector.mgi_allele_name_prediction = mgi_allele_name_prediction
    targ_rep_targeting_vector.save!
    @count_targeting_vector_updates += 1
    return true
  rescue => e
    puts "update_targ_rep_targeting_vector : ERROR updating targ_rep_targeting_vector with id #{row['tv_id']}"
    puts "update_targ_rep_targeting_vector : message : #{e.message}"
    @count_failed_targeting_vector_updates += 1
    return false
  end
end

##
## Insert a new row into the targ_rep_real_alleles table
##
def select_or_insert_real_allele ( gene_id, allele_name, allele_mgi_accession_id )

  puts "select_or_insert_real_allele : for : gene_id = #{gene_id}, allele_name = #{allele_name}, allele_mgi_accession_id = #{allele_mgi_accession_id}"

  # attempt to select an existing real allele first
  selected_real_allele = TargRep::RealAllele.where( "gene_id = #{gene_id} AND allele_name = '#{allele_name}'" ).first

  if selected_real_allele.nil?
    # no existing real allele, insert a new one
    inserted_real_allele = insert_real_allele( gene_id, allele_name, allele_mgi_accession_id )
    if inserted_real_allele.nil?
      puts "select_or_insert_real_allele : failed to insert targ_rep_real_allele for gene_id = #{gene_id}, allele_name = #{allele_name}, allele_mgi_accession_id = #{allele_mgi_accession_id}"
      return nil
    else
      inserted_real_allele_id = inserted_real_allele.id
      puts "select_or_insert_real_allele : inserted new real_allele with id #{inserted_real_allele_id}"
      return inserted_real_allele_id
    end
  else
    # check in case we can update with an mgi_accession_id, i.e. allele is a guess until confirmed and jax assigns an mgi id
    if selected_real_allele.mgi_accession_id.nil?
      unless allele_mgi_accession_id.nil? || allele_mgi_accession_id.to_s == ''
        begin
          selected_real_allele.mgi_accession_id = allele_mgi_accession_id
          selected_real_allele.save!
        rescue => e
          puts "select_or_insert_real_allele : ERROR : failed to update targ_rep_real_alleles attribute mgi_accession_id to #{allele_mgi_accession_id} for id #{selected_real_allele.id}, messages : "
          puts "select_or_insert_real_allele : message : #{e.message}"
        end
      end
    end

    puts "select_or_insert_real_allele : insert unnecessary, real_allele already exists with id #{selected_real_allele.id}"
    return selected_real_allele.id
  end
end

##
## Insert a new real allele row
##
def insert_real_allele( gene_id, allele_name, allele_mgi_accession_id )

  new_real_allele = TargRep::RealAllele.new(:gene_id=> gene_id, :allele_name => allele_name)

  # mgi_accession_id is optional
  unless allele_mgi_accession_id.nil? || allele_mgi_accession_id.to_s == ''
    new_real_allele.mgi_accession_id = allele_mgi_accession_id
  end

  begin
    new_real_allele.save!
    @count_real_allele_inserts += 1
    return new_real_allele
  rescue => e
    puts "insert_real_allele_id : ERROR inserting new real allele id with gene_id = #{gene_id}, allele_name = #{allele_name} and mgi_accession_id = #{allele_mgi_accession_id}"
    puts "insert_real_allele_id : message : #{e.message}"
    @count_failed_real_allele_inserts += 1
    return nil
  end
end

##
## Select an es_cell for the targeting_vector_id
##
def select_es_cell_for_targeting_vector( targeting_vector_id )
  puts "select_es_cell_for_targeting_vector : for : targeting vector = #{targeting_vector_id}"

  es_cell = TargRep::EsCell.where( "targeting_vector_id = #{targeting_vector_id} AND allele_type != 'e'").order(:allele_type, :id).limit(1).first
  return es_cell
end

# any initialisation here
initialise

# targ_rep_es_cells
check_targ_rep_es_cells

# mi_attempts
check_mi_attempts

# phenotype_attempts table
check_phenotype_attempts

# mouse_allele_mods
check_mouse_allele_mods

# targ_rep_targeting_vectors
check_targ_rep_targeting_vectors

# any cleanup tasks here
cleanup