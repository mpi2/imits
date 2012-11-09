Bundler.require(:migration)

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
  ## We're using an Abstract class here so we can re-use all these methods for the different classes we need to migrate.
  ##
  class Abstract

    attr_accessor :row

    def initialize(row = {})
      @row ||= row
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

end

namespace :migrate do

  desc "Import users from TargRep. Match duplicate users by email address."
  task :users => :environment do

    ## Load all TargRep users into an array
    users = LegacyTargRep::User.all
    ## Load all iMits users
    imits_users = User.scoped

    puts "Number of TargRep users: #{users.size}"
    puts "Number of iMits users: #{imits_users.count}"

    created_users = Array.new.tap do |array|
      users.each do |user|
        if imits_user = imits_users.where(:email => user.email).first
          ## Update existing user with Legacy ID
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
            #if new_user.save!
              ## Record the email/password in an array so we can notify new users.
              array << [new_user.email, new_user.password].join(", ")
            #end
          end
        end
      end
    end

    created_users_output_path = File.join(Rails.root, 'tmp', 'created_users.csv')
    created_users_string = created_users.join("\n")

    File.open(created_users_output_path, 'w') do |file|
      file.write(created_users_string)
    end

    puts "Created users output saved to: #{created_users_output_path}"
  end

end