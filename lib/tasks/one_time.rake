namespace :one_time do

  desc 'Back-fill MiPlans from MiAttempt data'
  task :back_fill_mi_plans_from_mi_attempts => :environment do
    MiAttempt.transaction do
      MiAttempt.all.each do |mi_attempt|
        begin
          gene = mi_attempt.es_cell.gene
          consortium = mi_attempt.consortium
          production_centre = mi_attempt.production_centre

          mi_plan = MiPlan.find_by_gene_id_and_consortium_id_and_production_centre_id(
            gene, consortium, production_centre)
          if ! mi_plan
            MiPlan.create!(
              :gene => gene,
              :consortium => consortium,
              :production_centre => production_centre,
              :mi_plan_status => MiPlanStatus.find_by_name!('Assigned'),
              :mi_plan_priority => MiPlanPriority.first
            )
          end
        rescue Exception => e
          e2 = RuntimeError.new("(#{e.class.name}): On\n\n#{mi_attempt.to_json}\n\n#{e.message}")
          e2.set_backtrace(e.backtrace)
          raise e2
        end
      end
    end
  end # :back_fill_mi_plans_from_mi_attempts

  desc 'Back-fill User Names'
  task :back_fill_user_names => :environment do
    {
      'a.mallon@har.mrc.ac.uk' => 'Ann-Marie Mallon',
      'abradley@sanger.ac.uk' => 'Alan Bradley',
      'aq2@sanger.ac.uk' => 'Asfand Qazi',
      'ayadi@igbmc.fr' => '',
      'bliu@bcm.edu' => '',
      'brendan.doe@ibc.cnr.it' => 'Brendan Doe',
      'd.lynch@har.mrc.ac.uk' => '',
      'dgm@sanger.ac.uk' => 'David Melvin',
      'do2@sanger.ac.uk' => 'Darren Oakley',
      'francesco.chiani@emma.cnr.it' => 'Francesco Chiani',
      'h.gates@har.mrc.ac.uk' => '',
      'htgt@sanger.ac.uk' => 'HTGT Data Loading Robot',
      'i.johnson@har.mrc.ac.uk' => '',
      'j.stevenson@har.mrc.ac.uk' => '',
      'j.vowles@har.mrc.ac.uk' => '',
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
      'mjustice@bcm.edu' => '',
      'mng@sanger.ac.uk' => 'Mark Griffiths',
      'n.adams@har.mrc.ac.uk' => '',
      'roland.friedel@helmholtz-muenchen.de' => 'Roland Friedel',
      'rrs@sanger.ac.uk' => 'Ramiro Ramirez-Solis',
      's.marschall@gsf.de' => '',
      's.wells@har.mrc.ac.uk' => '',
      'selloum@igbmc.fr' => '',
      'skarnes@sanger.ac.uk' => 'Bill Skarnes',
      'vvi@sanger.ac.uk' => 'Vivek Iyer'
    }.each do |email,name|
      begin
        user = User.find_by_email!(email)
        unless name.blank?
          user.name = name
          user.save
        end
      rescue Exception => e
        e2 = RuntimeError.new("(#{e.class.name}): On\n\n#{mi_attempt.to_json}\n\n#{e.message}")
        e2.set_backtrace(e.backtrace)
        raise e2
      end
    end
  end

end
