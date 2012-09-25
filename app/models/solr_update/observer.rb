module SolrUpdate::Observer
  class MiAttempt
    def after_save(mi)
      SolrUpdate::Queue.enqueue_for_update(mi)
    end

    def after_destroy(mi)
      SolrUpdate::Queue.enqueue_for_delete(mi)
    end
  end

  class PhenotypeAttempt
    def after_save(pa)
      SolrUpdate::Queue.enqueue_for_update(pa)
    end

    def after_destroy(pa)
      SolrUpdate::Queue.enqueue_for_delete(pa)
    end
  end
end
