class LegacyTargRep
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

    def es_cells
      LegacyTargRep::EsCell.where(:allele_id => self[:id])
    end

  end
end