require 'legacy_targ_rep'

def migration_dependancies(*models)
  models.each do |m|
    unless m.count > 0
      raise "You have missed a migration. #{m} does not have any records."
    end
  end
end

namespace :migrate do

  desc "Test"
  task :test => :environment do
    puts LegacyTargRep::Allele.count
    puts LegacyTargRep::User.count
  end

  desc "Migrate EsCellDistributionCentre data from TargRep. Keep TargRep IDs."
  task :es_cell_distribution_centres => :environment do

    begin
      
      LegacyTargRep.export_mysqlsql_import_postgresql('centres', 'targ_rep_es_cell_distribution_centres')

    rescue => e
      puts "EsCellDistributionCentre migration failed. Rolling back."
      TargRep::EsCellDistributionCentre.delete_all
      puts e
    end
  end


  desc "Import users from TargRep. Match duplicate users by email address."
  task :users => :environment do

    puts "You should have already have migrated the EsCellDistributionCentre table when you run this."
    migration_dependancies(TargRep::EsCellDistributionCentre)

    ## Load all TargRep users into an array
    users = LegacyTargRep::User.all
    ## Load all iMits users
    imits_users = User.scoped

    created_users = Array.new.tap do |array|
      users.each do |user|
        if imits_user = imits_users.where(:email => user.email).first
          ## Update existing user with Legacy ID
          puts "Updating user #{user.email}"
          imits_user.legacy_id = user.id
          imits_user.es_cell_distribution_centre_id = user[:centre_id]
          imits_user.save
        else

          ## Get production centre name from hash.
          unless production_centre = LegacyTargRep::User::PRODUCTION_CENTRE_ALLOCATIONS[user.email]
            raise StandardError, "User #{user.email} has not been manually matched to a production centre."
          end

          ## Look up production centre or skip (if it's a `delete`).
          if production_centre = Centre.find_by_name(production_centre)
            ## Create unknown TargRep user
            new_user = User.new
            new_user.email = user.email
            ## Set random hexidecimal password
            new_user.password = new_user.password_confirmation = SecureRandom.hex(8)
            ## Matched in above hash.
            new_user.production_centre_id = production_centre.id
            ##
            ## Centre ID
            ## To be copied wholesale from the current centres table in the TargRep database
            ## However this will be renamed es_cell_distribution_centres. ID's should match.
            ## Can be null.
            ##
            new_user.es_cell_distribution_centre_id = user[:centre_id]
            ## Save TargRep id for mapping & potential audits.
            new_user.legacy_id = user.id
            ## Save and raise an exception if it fails.
            puts "Creating use #{new_user.email}"
            if new_user.save!
              ##
              ## Record the email/password in a comma delimited string
              ## for populating a CSV of created users.
              ##
              array << [new_user.email, new_user.password].join(", ")
            end
          end
        end
      end
    end

    ##
    ## Simple output to CSV, no need to mess around with built in CSV methods.
    ##
    created_users_output_path = File.join(Rails.root, 'tmp', 'created_users.csv')
    created_users_string = created_users.join("\n")
    File.open(created_users_output_path, 'w') do |file|
      file.write(created_users_string)
    end

    puts "Created users output saved to: #{created_users_output_path}"
  end

  desc "Migrate Targeting vector data from TargRep. Keep TargRep IDs."
  task :mutation_method_type_and_subtype => :environment do

    puts "You should have already have migrated the EsCellDistributionCentre, User tables when you run this."
    migration_dependancies(TargRep::EsCellDistributionCentre, User)

    begin
      
      LegacyTargRep.export_mysqlsql_import_postgresql('mutation_methods', 'targ_rep_mutation_methods')
      LegacyTargRep.export_mysqlsql_import_postgresql('mutation_types', 'targ_rep_mutation_types')
      LegacyTargRep.export_mysqlsql_import_postgresql('mutation_subtypes', 'targ_rep_mutation_subtypes')

    rescue => e
      puts "Mutation migration failed. Rolling back."
      TargRep::MutationMethod.delete_all
      TargRep::MutationType.delete_all
      TargRep::MutationSubtype.delete_all
      puts e
    end
  end

  desc "Import users from TargRep. Match duplicate users by email address."
  task :allele => :environment do

    puts "You should have already have migrated the EsCellDistributionCentre, User, MutationMethod, MutationType, MutationSubtype tables when you run this."
    migration_dependancies(TargRep::EsCellDistributionCentre, User, TargRep::MutationMethod, TargRep::MutationType, TargRep::MutationSubtype)

    failed_allele = {
      :failed => Array.new,
      :missing => Array.new
    }

    ActiveRecord::Base.observers.disable(:all)

    TargRep::Allele.transaction do
        
        ::TargRep::Allele.disable_auditing
        ActiveRecord::Base.observers.disable(:all)

        LegacyTargRep::Allele.all.each do |old_allele|

          ## Update MGI Accession ID or use TargRep copy.
          mgi_accession_id = LegacyTargRep::Allele::MODIFY_ALLELE[old_allele[:id].to_s.to_sym] || old_allele[:mgi_accession_id]

          ## Don't migrate removed Allele.
          next if LegacyTargRep::Allele::DELETE_ALLELE.include?(old_allele.id)
          ## Don't migrate Allele with no products.
          next if old_allele.no_products?

          if gene = Gene.find_by_mgi_accession_id(mgi_accession_id)

            allele = TargRep::Allele.new

            allele.id                  = old_allele[:id]
            allele.gene_id             = gene.id
            allele.assembly            = old_allele[:assembly]
            allele.chromosome          = old_allele[:chromosome]
            allele.strand              = old_allele[:strand]
            allele.homology_arm_start  = old_allele[:homology_arm_start]
            allele.homology_arm_end    = old_allele[:homology_arm_end]
            allele.loxp_start          = old_allele[:loxp_start]
            allele.loxp_end            = old_allele[:loxp_end]
            allele.cassette_start      = old_allele[:cassette_start]
            allele.cassette_end        = old_allele[:cassette_end]
            allele.cassette            = old_allele[:cassette]
            allele.backbone            = old_allele[:backbone]
            allele.subtype_description = old_allele[:subtype_description]
            allele.floxed_start_exon   = old_allele[:floxed_start_exon]
            allele.floxed_end_exon     = old_allele[:floxed_end_exon]
            allele.project_design_id   = old_allele[:project_design_id]
            allele.reporter            = old_allele[:reporter]
            allele.mutation_method_id  = old_allele[:mutation_method_id]
            allele.mutation_type_id    = old_allele[:mutation_type_id]
            allele.mutation_subtype_id = old_allele[:mutation_subtype_id]
            allele.cassette_type       = old_allele[:cassette_type]
            allele.created_at          = old_allele[:created_at]
            allele.updated_at          = old_allele[:updated_at]

            unless allele.save
              puts "This allele has failed to save with #{allele.errors.inspect}"
              puts allele.inspect
              puts old_allele.inspect
              failed_allele[:failed] << [old_allele[:id], allele.errors.inspect]
            end

          else
            ##
            ## Record failed genes
            ##
            puts "Could not find Gene with mgi_accession_id: #{old_allele.mgi_accession_id}"
            failed_allele[:missing] << [old_allele[:id], old_allele.mgi_accession_id]
          end
          
        end
  
    end

    LegacyTargRep.update_sequences('targ_rep_alleles')

    puts "----"
    puts "Could not match #{failed_allele[:missing].size} genes."
    puts "#{failed_allele[:failed].size} allele failed to migrate."
    puts "----"
    ## CSV these
    puts failed_allele.inspect

  end

  desc "Migrate Pipeline data from TargRep. Keep TargRep IDs. Merge new iMits Pipeline's and add description."
  task :pipelines => :environment do
    require 'targ_rep/pipeline'

    puts "You should have already have migrated the EsCellDistributionCentre, User, MutationMethod, MutationType, MutationSubtype, & Allele tables when you run this."
    migration_dependancies(TargRep::EsCellDistributionCentre, User, TargRep::MutationMethod, TargRep::MutationType, TargRep::MutationSubtype, TargRep::Allele)

    ActiveRecord::Base.observers.disable(:all)

    begin

      LegacyTargRep.export_mysqlsql_import_postgresql('pipelines', 'targ_rep_pipelines')
    
      puts "Find Pipeline in current iMits that don't exist in TargRep::Pipeline table. Add to TargRep::Pipeline with legacy_id of old pipeline_id."
      puts "Also update matching pipelines legacy_id in TargRep::Pipeline table."

      pipelines = {:updated => [], :created => []}

      ::TargRep::Pipeline.transaction do

        Pipeline.all.each do |pipeline|
          if targ_rep_pipeline = TargRep::Pipeline.find_by_name(pipeline.name)
            ##
            ##  Update legacy_id of matching Pipeline's found in both iMits & TargRep.
            ##  Update description, used in iMits & not TargRep.

            targ_rep_pipeline.legacy_id = pipeline.id
            targ_rep_pipeline.description = pipeline.description

            if targ_rep_pipeline.save
              pipelines[:updated] << targ_rep_pipeline.id
            end
          else
            ##
            ##  Create missing Pipeline's in TargRep::Pipeline table.
            ##

            targ_rep_pipeline = TargRep::Pipeline.new
            targ_rep_pipeline.name = pipeline.name
            targ_rep_pipeline.description = pipeline.description
            targ_rep_pipeline.legacy_id = pipeline.id
            if targ_rep_pipeline.save
              pipelines[:created] << targ_rep_pipeline.id
            end
          end
        end
      end

    rescue => e
      puts "Pipeline migration failed. Rolling back."
      TargRep::Pipeline.delete_all
      puts e
    end

  end

  desc "Migrate Targeting vector data from TargRep. Keep TargRep IDs."
  task :targeting_vectors => :environment do

    puts "You should have already have migrated the EsCellDistributionCentre, User, MutationMethod, MutationType, MutationSubtype, Allele, & Pipeline tables when you run this."
    migration_dependancies(TargRep::EsCellDistributionCentre, User, TargRep::MutationMethod, TargRep::MutationType, TargRep::MutationSubtype, TargRep::Allele, TargRep::Pipeline)

    begin
      
      LegacyTargRep.export_mysqlsql_import_postgresql('targeting_vectors', 'targ_rep_targeting_vectors', true)

    rescue => e
      puts "Targeting vector migration failed. Rolling back."
      TargRep::TargetingVector.delete_all
      puts e
    end
  end

  desc "Migrate EsCell data from TargRep. Match up with existing EsCells."
  task :es_cells => :environment do
    require 'targ_rep/pipeline'
    require 'targ_rep/es_cell'

    puts "You should have already have migrated the EsCellDistributionCentre, User, MutationMethod, MutationType, MutationSubtype, Allele, & Pipeline tables when you run this."
    migration_dependancies(TargRep::EsCellDistributionCentre, User, TargRep::MutationMethod, TargRep::MutationType, TargRep::MutationSubtype, TargRep::Allele, TargRep::Pipeline, TargRep::TargetingVector)

    ActiveRecord::Base.observers.disable(:all)

    matched_es_cells = {}

    begin

      number_of_es_cells = LegacyTargRep::EsCell.count
      sets = (number_of_es_cells.to_f / 1000.0).ceil

      legacy_es_cells = EsCell.all

      ::TargRep::EsCell.disable_auditing
      ActiveRecord::Base.observers.disable(:all)

      #LegacyTargRep::EsCell.all.each do |targ_rep_es_cell|
      #test_es_cell_names = ["EPD0719_1_C02", "EPD0033_3_A11", "EPD0033_3_C11", "EPD0054_1_C05", "EPD0090_4_C10", "EPD0090_4_H11", "EPD0571_3_F01", "EPD0083_2_E03"]

      #LegacyTargRep::EsCell.where(:name => test_es_cell_names).each do |targ_rep_es_cell|

      puts "Number of sets: #{sets}"

      `> failed_es_cells`

      sets.times do |i|
        offset = 1000 * i
        puts "Set ##{i}"
        ::TargRep::EsCell.transaction do
          LegacyTargRep::EsCell.limit(1000, offset).each do |targ_rep_es_cell|

            new_es_cell = ::TargRep::EsCell.new

            new_es_cell.id                                     = targ_rep_es_cell[:id]
            new_es_cell.name                                   = targ_rep_es_cell[:name]

            if allele = ::TargRep::Allele.find_by_id(targ_rep_es_cell[:allele_id])
              new_es_cell.allele_id                              = allele.id
            end

            if targeting_vector = TargRep::TargetingVector.find_by_id(targ_rep_es_cell[:targeting_vector_id])
              new_es_cell.targeting_vector_id                    = targeting_vector.id
            end

            new_es_cell.parental_cell_line                     = targ_rep_es_cell[:parental_cell_line]
            new_es_cell.allele_symbol_superscript              = targ_rep_es_cell[:allele_symbol_superscript]
            new_es_cell.mgi_allele_symbol_superscript          = targ_rep_es_cell[:allele_symbol_superscript]
            new_es_cell.comment                                = targ_rep_es_cell[:comment]
            new_es_cell.contact                                = targ_rep_es_cell[:contact]
            new_es_cell.ikmc_project_id                        = targ_rep_es_cell[:ikmc_project_id]
            new_es_cell.mgi_allele_id                          = targ_rep_es_cell[:mgi_allele_id]
            new_es_cell.pipeline_id                            = targ_rep_es_cell[:pipeline_id]
            new_es_cell.report_to_public                       = targ_rep_es_cell[:report_to_public]
            new_es_cell.strain                                 = targ_rep_es_cell[:strain]
            new_es_cell.production_qc_five_prime_screen        = targ_rep_es_cell[:production_qc_five_prime_screen]
            new_es_cell.production_qc_three_prime_screen       = targ_rep_es_cell[:production_qc_three_prime_screen]
            new_es_cell.production_qc_loxp_screen              = targ_rep_es_cell[:production_qc_loxp_screen]
            new_es_cell.production_qc_loss_of_allele           = targ_rep_es_cell[:production_qc_loss_of_allele]
            new_es_cell.production_qc_vector_integrity         = targ_rep_es_cell[:production_qc_vector_integrity]
            new_es_cell.user_qc_map_test                       = targ_rep_es_cell[:user_qc_map_test]
            new_es_cell.user_qc_karyotype                      = targ_rep_es_cell[:user_qc_karyotype ]
            new_es_cell.user_qc_tv_backbone_assay              = targ_rep_es_cell[:user_qc_tv_backbone_assay]
            new_es_cell.user_qc_loxp_confirmation              = targ_rep_es_cell[:user_qc_loxp_confirmation]
            new_es_cell.user_qc_southern_blot                  = targ_rep_es_cell[:user_qc_southern_blot]
            new_es_cell.user_qc_loss_of_wt_allele              = targ_rep_es_cell[:user_qc_loss_of_wt_allele]
            new_es_cell.user_qc_neo_count_qpcr                 = targ_rep_es_cell[:user_qc_neo_count_qpcr]
            new_es_cell.user_qc_lacz_sr_pcr                    = targ_rep_es_cell[:user_qc_lacz_sr_pcr]
            new_es_cell.user_qc_mutant_specific_sr_pcr         = targ_rep_es_cell[:user_qc_mutant_specific_sr_pcr]
            new_es_cell.user_qc_five_prime_cassette_integrity  = targ_rep_es_cell[:user_qc_five_prime_cassette_integrity]
            new_es_cell.user_qc_neo_sr_pcr                     = targ_rep_es_cell[:user_qc_neo_sr_pcr]
            new_es_cell.user_qc_five_prime_lr_pcr              = targ_rep_es_cell[:user_qc_five_prime_lr_pcr]
            new_es_cell.user_qc_three_prime_lr_pcr             = targ_rep_es_cell[:user_qc_three_prime_lr_pcr]
            new_es_cell.user_qc_comment                        = targ_rep_es_cell[:user_qc_comment]

            ##
            ## Match TargRep EsCells to iMits EsCells
            ##
            if es_cell = legacy_es_cells.find {|e| e.name == targ_rep_es_cell[:name]}
              new_es_cell.mutation_subtype                       = es_cell.mutation_subtype
              new_es_cell.legacy_id                              = es_cell.id
            end

            #puts "Saving: #{new_es_cell.name}"
            if new_es_cell.save
              if new_es_cell.legacy_id
                matched_es_cells[new_es_cell.legacy_id] = new_es_cell.id
              end
            else
              `echo '#{targ_rep_es_cell.row}\nErrors: #{new_es_cell.errors.inspect}\n\n' >> failed_es_cells`
            end
          end
        end
      end

      LegacyTargRep.update_sequences('targ_rep_es_cells')

      puts "Update MiAttempts with new EsCell id"
      MiAttempt.transaction do

        remove_es_cells = EsCell.find_all_by_name(["Chd7-FL", "Atp2b2-MAME", "Tmc1-MAMG"]).map(&:id)
        mi_attempts = MiAttempt.find_all_by_es_cell_id(remove_es_cells)
        mi_attempts.map(&:destroy)

        ## We're looping through MiAttempts, using update_all will cause an issue where new ids could be mistaken for legacy ids.
        MiAttempt.order('id ASC').each do |mi|
          new_id = matched_es_cells[mi.es_cell_id]
          MiAttempt.update_all({:es_cell_id => new_id.to_i, :legacy_es_cell_id => mi.es_cell_id}, {:id => mi.id})
          
          if new_id.blank?
            `echo '#{mi.inspect}\n\n' >> missing_es_cell_for_mi_attempts`
          end
        end
      end

    rescue SystemExit, Interrupt, SignalException
      puts "\nEsCell migration canceled. Rolling back.\n"
      ActiveRecord::Base.connection.execute('truncate targ_rep_es_cells')
    rescue Exception => e
      puts "\nEsCell migration failed. Rolling back.\n"
      ActiveRecord::Base.connection.execute('truncate targ_rep_es_cells')
      puts e
      puts e.backtrace.join("\n")
    end

  end

  desc "Migrate DistributionQc data from TargRep."
  task :distribution_qcs => :environment do
    require 'targ_rep/pipeline'
    require 'targ_rep/es_cell'

    puts "You should have already have migrated the EsCellDistributionCentre, User, MutationMethod, MutationType, MutationSubtype, Allele, Pipeline, & EsCell tables when you run this."
    migration_dependancies(TargRep::EsCellDistributionCentre, User, TargRep::MutationMethod, TargRep::MutationType, TargRep::MutationSubtype, TargRep::Allele, TargRep::Pipeline, TargRep::TargetingVector, TargRep::EsCell)

    begin
      
      distribution_qcs = {
        :failed =>  [],
        :created => []
      }

      ::TargRep::DistributionQc.transaction do

        ::TargRep::DistributionQc.disable_auditing

        LegacyTargRep::DistributionQc.all.each do |targ_rep_distribution_qc|
          
          targ_rep_distribution_qc.row[:es_cell_distribution_centre_id] = targ_rep_distribution_qc[:centre_id]
          targ_rep_distribution_qc.row.delete(:centre_id)

          distribution_qc = ::TargRep::DistributionQc.new(targ_rep_distribution_qc.row)
          distribution_qc.id = targ_rep_distribution_qc[:id]

          if distribution_qc.save
            distribution_qcs[:created] << distribution_qc.id
          else
            puts distribution_qc.errors.inspect
            distribution_qcs[:failed] << targ_rep_distribution_qc.id
          end
  
        end
      end

      LegacyTargRep.update_sequences('targ_rep_distribution_qcs')

      puts "Created #{distribution_qcs[:created].size} DistributionQc"
      puts "Failed to create #{distribution_qcs[:failed].size} DistributionQc"

    end
  end


end
