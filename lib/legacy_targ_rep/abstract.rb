class LegacyTargRep
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
    def [](m)
      self.row[m]
    end

    def method_missing(sym, *args, &block)
      if @row[sym.to_sym].blank?
        super
      else
        @row[sym]
      end
    end

    ## id wont appear in method missing. Override.
    def id
      self.row[:id]
    end

    ##
    ## Class methods
    ##
    class << self

      attr_accessor :dataset, :tablename

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
        @dataset ||= LegacyTargRep.database_connection[self.tablename].order(:created_at)
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

      def count
        self.dataset.count
      end

      def limit(limit, offset = nil)
        self.dataset.limit(limit, offset).map {|row| self.new(row)}
      end

    end

  end
end