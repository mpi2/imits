module SolrUpdate::Util
  def allele_image_url(allele_id, args = {})
    if args[:cre]
      action = 'allele-image-cre'
    elsif args[:flp]
      action = 'allele-image-flp'
    else
      action = 'allele-image'
    end

    if args[:simple]
      action << '?simple=true'
    end

    return SolrUpdate::Config.fetch('targ_rep_url') + "/alleles/#{allele_id}/#{action}"
  end

  def genbank_file_url(allele_id, args = {})
    if args[:cre]
      action = 'escell-clone-cre-genbank-file'
    elsif args[:flp]
      action = 'escell-clone-flp-genbank-file'
    else
      action = 'escell-clone-genbank-file'
    end

    return SolrUpdate::Config.fetch('targ_rep_url') + "/alleles/#{allele_id}/#{action}"
  end
end
