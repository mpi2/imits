namespace :one_time do

  desc 'Back-fill User Names'
  task :back_fill_user_names => :environment do
    {
      'a.mallon@har.mrc.ac.uk' => 'Ann-Marie Mallon',
      'abradley@sanger.ac.uk' => 'Alan Bradley',
      'aq2@sanger.ac.uk' => 'Asfand Qazi',
      'ayadi@igbmc.fr' => 'Abdel Ayadi',
      'bliu@bcm.edu' => 'Bin Liu',
      'brendan.doe@ibc.cnr.it' => 'Brendan Doe',
      'd.lynch@har.mrc.ac.uk' => 'Dee Lycnh',
      'dgm@sanger.ac.uk' => 'David Melvin',
      'do2@sanger.ac.uk' => 'Darren Oakley',
      'francesco.chiani@emma.cnr.it' => 'Francesco Chiani',
      'h.gates@har.mrc.ac.uk' => 'Hilary Gates',
      'htgt@sanger.ac.uk' => 'HTGT Data Loading Robot',
      'i.johnson@har.mrc.ac.uk' => '',
      'j.stevenson@har.mrc.ac.uk' => '',
      'j.vowles@har.mrc.ac.uk' => 'Jane Vowles',
      'jb27@sanger.ac.uk' => 'Joanna Bottomley',
      'jc3@sanger.ac.uk' => 'Jody Clements',
      'jdrapp@ucdavis.edu' => 'Jared Rapp',
      'jkw@sanger.ac.uk' => 'Jacqui White',
      'joel.schick@helmholtz-muenchen.de' => 'Joel Schick',
      'kps@sanger.ac.uk' => 'Karen Steel',
      'l.teboul@har.mrc.ac.uk' => 'Lydia Teboul',
      'lauryl.nutter@phenogenomics.ca' => 'Lauryl Nutter',
      'm.fray@har.mrc.ac.uk' => 'Martin Fray',
      'michael.hagn@gsf.de' => 'Michael Hagn',
      'mjustice@bcm.edu' => 'Monica Justice',
      'mng@sanger.ac.uk' => 'Mark Griffiths',
      'n.adams@har.mrc.ac.uk' => 'Niels Adams',
      'roland.friedel@helmholtz-muenchen.de' => 'Roland Friedel',
      'rrs@sanger.ac.uk' => 'Ramiro Ramirez-Solis',
      's.marschall@gsf.de' => 'Susan Marschall',
      's.wells@har.mrc.ac.uk' => 'Sara Wells',
      'selloum@igbmc.fr' => 'Mohammed Selloum',
      'skarnes@sanger.ac.uk' => 'Bill Skarnes',
      'vvi@sanger.ac.uk' => 'Vivek Iyer'
    }.each do |email,name|
      user = User.find_by_email!(email)
      unless name.blank?
        user.name = name
        user.save!
      end
    end
  end

end
