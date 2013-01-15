class LegacyTargRep

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
  
end