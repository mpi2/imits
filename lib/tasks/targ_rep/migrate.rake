Bundler.require(:migration)

DATABASE_CONFIG = Rails.configuration.database_configuration[Rails.env]

class LegacyTargRep

  class RecordNotFound < StandardError; end
  class TableNotFound < StandardError; end

  attr_accessor :config, :database_connection
  
  ##
  ## Get TargRep config. This needs to be in config/database.targ_rep.yml
  ##
  def self.config
    @config ||= YAML.load_file("#{Rails.root}/config/database.targ_rep.yml")[Rails.env.to_s]
  end

  ##
  ## Connect to the TargRep MySQL database.
  ##
  def self.database_connection
    Rails.logger.info "Connecting to #{Rails.env.to_s} database `#{config['database']}` with `#{config['username']}@#{config['password']}`"
    
    Sequel.mysql2(config['database'], 
      :user => config['username'],
      :password => config['password'],
      :host => config['host'])
  end

  ##
  ## Alter table column
  ##
  def self.change_to_type(bools, conn, to_type)
    bools.each_pair do |table, cols|
      cols.each do |col|
        conn.execute "alter table #{table} alter column #{col} type #{to_type} 
                                  USING (#{col}::#{to_type});"
      end
    end
  end

  ##
  ## Handle MySQL, PostgreSQL boolean differences. Return column defaults to we can reverse it.
  ##
  def self.convert_boolean_to_integer(tablename)
    bools = {}
    defaults = {}

    conn = ActiveRecord::Base.connection
    table = conn.columns(tablename)

    begin

      ## Generate hash of boolean columns
      table.each do |col|
        if col.type.to_s == "boolean"
          (bools[tablename] ||= []) << col.name
          (defaults[tablename] ||= {})[col.name] = col.default if !col.default.nil?
        end

        ## Drop boolean defaults
        defaults.each_pair do |table, cols|
          cols.each_key do |col|
            conn.execute "alter table #{tablename} alter column #{col} DROP DEFAULT"      
          end
        end
      end

      change_to_type(bools, conn, :integer)

    rescue
      restore_column_defaults_and_boolean_type(tablename, [defaults, bools])
    end

    return [defaults, bools]
  end

  def self.restore_column_defaults_and_boolean_type(tablename, table_data)
    defaults, bools = table_data

    conn = ActiveRecord::Base.connection
    change_to_type(bools, conn, :boolean)

    defaults.each_pair do |table, cols|
      cols.each_pair do |col, default|
        conn.execute "alter table #{table} alter column #{col} SET DEFAULT #{default}"
      end
    end
  end

  ##
  ## Dump MySQL data, escape for PSql. Import into PSql.
  ##
  def self.export_mysqlsql_import_postgresql(tablename, new_tablename, has_booleans = false)

    ## If a table has boolean columns convert them to integers so that PostgreSQL doesn't complain.
    if has_booleans
      table_data = convert_boolean_to_integer(new_tablename)
    end

    conn = ActiveRecord::Base.connection

    if tablename == 'targeting_vectors'
      unless (conn.columns(new_tablename).map(&:name).include?('created_by'))
        conn.execute "alter table #{new_tablename} add column created_by integer"
        conn.execute "alter table #{new_tablename} add column updated_by integer"
      end
    end

    exported_file = File.join(Rails.root, 'tmp', "#{tablename}.sql")

    begin
      puts "Export Mysql database"
      dump_command = "mysqldump --compatible=postgresql --skip-comments --no-create-info -u #{LegacyTargRep.config['username']} #{LegacyTargRep.config['password'].blank? ? '' : "-p #{LegacyTargRep.config['password']}"} --skip-extended-insert --complete-insert --skip-opt #{LegacyTargRep.config['database']} #{tablename} > #{exported_file}"
      puts dump_command
      `#{dump_command}`
      rename_table = %Q[sed -i "" "s/#{tablename}/#{new_tablename}/g" #{exported_file}]
      puts rename_table
      `#{rename_table}`

      escaped_file_string = File.open(exported_file) do |f|
        file_body = f.read
        file_body = file_body.gsub(/\\\'/, "\'\'").gsub(/\\r/, "\r").gsub(/\\n/, "\n")
      end

      escaped_file = File.join(Rails.root, 'tmp', "#{tablename}-escaped.sql")
      File.open(escaped_file, 'w') {|f| f.write(escaped_file_string)}
    
      puts "Import database into iMits"
      import_command = %Q[psql -W -h #{DATABASE_CONFIG['host']} -f #{escaped_file} #{DATABASE_CONFIG['database']} -U #{DATABASE_CONFIG['username']}]
    # puts import_command      

      `#{import_command}`

    rescue => e

      puts e.inspect

      if has_booleans
        restore_column_defaults_and_boolean_type(new_tablename, table_data)
      end
    end

    unless conn.execute("select count(*) from #{new_tablename}").first["count"].to_i > 0
      raise "Migration failed."
    end

    ## The imported integer columns that should be booleans should be set back to booleans.
    if has_booleans
      restore_column_defaults_and_boolean_type(new_tablename, table_data)
    end

    if tablename == 'targeting_vectors'
      conn.execute "alter table #{new_tablename} drop column created_by"
      conn.execute "alter table #{new_tablename} drop column updated_by"
    end

    puts "Rescyning table sequence based on last id in table."
    conn = ActiveRecord::Base.connection
    if conn.columns(new_tablename).detect{|i|i.name == "id"}
      conn.execute "SELECT setval('#{new_tablename}_id_seq', (SELECT max(id) FROM #{new_tablename}))"
    end

  end

  ##
  ## We're using an Abstract class here so we can re-use all these methods for the different classes we need to migrate.
  ##
  class Abstract

    attr_accessor :row

    def initialize(row = {})
      @row ||= row
    end

    def [](m)
      self.row[m]
    end

    ##
    ## Easier access to an objects data.
    ##
    def method_missing(sym, *args, &block)
      if @row[sym.to_sym].blank?
        super
      else
        @row[sym]
      end
    end

    ##
    ## Class methods
    ##
    class << self

      attr_accessor :tablename

      ##
      ## Find tablename based on class. You can override this in the specific class.
      ##
      def tablename
        begin
          @tablename ||= self.to_s.tableize.match(/legacy_targ_rep\/(.*)/)[1].to_sym
        rescue
          raise LegacyTargRep::TableNotFound
        end
      end

      ##
      ## Retrieve table as Sequel dataset. You should always sort the table by something.
      ##
      def dataset
        LegacyTargRep.database_connection[self.tablename].order(:created_at)
      end

      ##
      ## Get all rows as an array. You cannot chain this function. This isn't ActiveRecord.
      ##
      def all
        self.dataset.map{|row| self.new(row) }
      end

      ##
      ## Alias to Sequel `where` method. Returned as array. You cannot chain this function. This isn't ActiveRecord
      ##
      def where(*conditions)
        self.dataset.where(conditions).map{|row| self.new(row) } 
      end

      ##
      ## Find by id and raise exception if not found
      ##
      def find(id)
        self.dataset.where('id = ?', id).first or raise LegacyTargRep::RecordNotFound
      end

      ##
      ## Find by id without raising an exception
      ##
      def find_by_id(id)
        self.dataset.where('id = ?', id).first
      end

    end

  end

  class User < Abstract
    ##
    ## TargRep users to be created need production centres. List provided by Vivek.
    ## Users listed with 'delete' will not be migrated.
    ##
    PRODUCTION_CENTRE_ALLOCATIONS = {
      "hmp@sanger.ac.uk"      => "WTSI",
      "io1@sanger.ac.uk"      => "delete",
      "soliu@cc.umanitoba.ca" => "TCP",
      "this_acc_went_wrong@sanger.ac.uk" => "delete",
      "db7@sanger.ac.uk" => "WTSI",
      "dg4@sanger.ac.uk" => "WTSI",
      "sonja.schick@helmholtz-muenchen.de" => "delete",
      "jmason@informatics.jax.org"         => "delete",
      "viola.maier@helmholtz-muenchen.de"  => "HMGU",
      "hicksgg@cc.umanitoba.ca"    => "TCP",
      "alejo.mujica@regeneron.com" => "delete",
      "mh8@sanger.ac.uk"  => "delete",
      "af11@sanger.ac.uk" => "WTSI"
    }
  end

  class Allele < Abstract
    ##
    ##  The following are based on the log output of Asfan's Allele update script in TargRep
    ##
    ##  Redundant allele to be removed.
    ##
    DELETE_ALLELE = [8069, 16291, 16920, 16944, 30851]
    ##
    ##  Re-map MGI Accession ID
    ##
    MODIFY_ALLELE = {
      :"14404" => "MGI:1916648",
      :"17307" => "MGI:1328322",
      :"19914" => "MGI:96877",
      :"20385" => "MGI:98541",
      :"20787" => "MGI:1916648",
      :"24581" => "MGI:1328322",
      :"30912" => "MGI:3704417",
      :"33198" => "MGI:1354949"
    }
  end

  class Pipeline < Abstract; end

end

def migration_dependancies(*models)
  models.each do |m|
    unless m.count > 0
      raise "You have missed a migration. #{m} does not have any records."
    end
  end
end

namespace :migrate do

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
          imits_user.update_attribute(:legacy_id, user.id)
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
            new_user.es_cell_distribution_centre_id = user.row[:centre_id]
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
    #end
  end

  desc "Import users from TargRep. Match duplicate users by email address."
  task :allele => :environment do

    puts "You should have already have migrated the EsCellDistributionCentre, User, MutationMethod, MutationType, MutationSubtype tables when you run this."
    migration_dependancies(TargRep::EsCellDistributionCentre, User, TargRep::MutationMethod, TargRep::MutationType, TargRep::MutationSubtype)

    failed_allele = {
      :failed => Array.new,
      :missing => Array.new
    }

    TargRep::Allele.transaction do
      

        LegacyTargRep::Allele.all.each do |old_allele|

          ## Update MGI Accession ID or use TargRep copy.
          mgi_accession_id = LegacyTargRep::Allele::MODIFY_ALLELE[old_allele[:id].to_s.to_sym] || old_allele[:mgi_accession_id]

          ## Don't migrate removed Allele.
          next if LegacyTargRep::Allele::DELETE_ALLELE.include?(old_allele.id)

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
              failed_allele[:failed] << [old_allele.id, allele.errors.inspect]
            end

          else
            ##
            ## Record failed genes
            ##
            puts "Could not find Gene with mgi_accession_id: #{old_allele.mgi_accession_id}"
            failed_allele[:missing] << [old_allele.id, old_allele.mgi_accession_id]
          end
          
        end
  
     end

    puts "----"
    puts "Could not match #{failed_allele[:missing].size} genes."
    puts "#{failed_allele[:failed].size} allele failed to migrate."
    puts "----"
    puts failed_allele.inspect

  end

  desc "Migrate Pipeline data from TargRep. Keep TargRep IDs. Merge new iMits Pipeline's and add description."
  task :pipelines => :environment do
    require 'targ_rep/pipeline'

    puts "You should have already have migrated the EsCellDistributionCentre, User, MutationMethod, MutationType, MutationSubtype, & Allele tables when you run this."
    migration_dependancies(TargRep::EsCellDistributionCentre, User, TargRep::MutationMethod, TargRep::MutationType, TargRep::MutationSubtype, TargRep::Allele)

    begin

      LegacyTargRep.export_mysqlsql_import_postgresql('pipelines', 'targ_rep_pipelines')
    
      puts "Find Pipeline in current iMits that don't exist in TargRep::Pipeline table. Add to TargRep::Pipeline with legacy_id of old pipeline_id."
      puts "Also update matching pipelines legacy_id in TargRep::Pipeline table."

      pipelines = {:updated => [], :created => []}

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

end