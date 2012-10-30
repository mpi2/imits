module SolrUpdate::Observer
  class MiAttempt < ActiveRecord::Observer
    observe :mi_attempt

    def initialize
      super
      @enqueuer = SolrUpdate::Enqueuer.new
    end

    def after_save(mi)
      @enqueuer.mi_attempt_updated(mi)
    end

    def after_destroy(mi)
      @enqueuer.mi_attempt_destroyed(mi)
    end

    public_class_method :new
  end

  class PhenotypeAttempt < ActiveRecord::Observer
    observe :phenotype_attempt

    def initialize
      super
      @enqueuer = SolrUpdate::Enqueuer.new
    end

    def after_save(pa)
      @enqueuer.phenotype_attempt_updated(pa)
    end

    def after_destroy(pa)
      @enqueuer.phenotype_attempt_destroyed(pa)
    end

    public_class_method :new
  end

  class AnyWithMiAttempts < ActiveRecord::Observer
    observe :mi_plan, :"TargRep::EsCell", :gene

    def initialize
      super
      @enqueuer = SolrUpdate::Enqueuer.new
    end

    def after_save(object)
      @enqueuer.any_with_mi_attempts_updated(object)
    end

    public_class_method :new
  end
end
