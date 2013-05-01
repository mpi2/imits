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

  class DistributionCentres < ActiveRecord::Observer
    observe 'MiAttempt::DistributionCentre', 'PhenotypeAttempt::DistributionCentre'

    def initialize
      super
      @enqueuer = SolrUpdate::Enqueuer.new
    end

    def after_save(object)
      @enqueuer.update_mi_or_phenotype_attempt(object)
    end

    def after_destroy(object)
      @enqueuer.update_mi_or_phenotype_attempt(object)
    end

    public_class_method :new
  end

  class EsCell < ActiveRecord::Observer
    observe :"TargRep::EsCell"

    def initialize
      super
      @enqueuer = SolrUpdate::Enqueuer.new
    end

    def after_save(es_cell)
      @enqueuer.es_cell_updated(es_cell)
    end

    def after_destroy(es_cell)
      @enqueuer.es_cell_destroyed(es_cell)
    end

    public_class_method :new
  end

  class Allele < ActiveRecord::Observer
    observe :"TargRep::Allele"

    def initialize
      super
      @enqueuer = SolrUpdate::Enqueuer.new
    end

    def after_save(allele)
      @enqueuer.allele_updated(allele)
    end

    def after_destroy(allele)
      @enqueuer.allele_destroyed(allele)
    end

    public_class_method :new
  end

  class MiPlan < ActiveRecord::Observer
    observe :mi_plan

    def initialize
      super
      @enqueuer = SolrUpdate::Enqueuer.new
    end

    def after_save(object)
      @enqueuer.mi_plan_updated(object)
    end

    def after_destroy(object)
      @enqueuer.mi_plan_destroyed(object)
    end

    public_class_method :new
  end

end
