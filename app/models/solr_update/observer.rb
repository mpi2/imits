module SolrUpdate::Observer
  class MiAttempt < ActiveRecord::Observer
    observe :mi_attempt

    def after_save(mi)
      SolrUpdate::Queue.enqueue_for_update(mi)
    end

    def after_destroy(mi)
      SolrUpdate::Queue.enqueue_for_delete(mi)
    end

    public_class_method :new
  end

  class PhenotypeAttempt < ActiveRecord::Observer
    observe :phenotype_attempt

    def after_save(pa)
      SolrUpdate::Queue.enqueue_for_update(pa)
    end

    def after_destroy(pa)
      SolrUpdate::Queue.enqueue_for_delete(pa)
    end

    public_class_method :new
  end
end
