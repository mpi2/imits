SITE_PATH = case Rails.env
when 'production' then
  'http://mousephenotype.org/imits'
when 'staging' then
  'http://i-dcc.org/staging/imits'
else
  'http://localhost:3000'
end

ALLELE_OVERALL_PASS_PATH = case Rails.env
when 'test' then
  # "#{Rails.configuration.htgt_root}/report/allele_overall_pass?view=csvdl"
  'test/db/allele_overall_pass.csv'
else
  # 'test/db/allele_overall_pass.csv'
  #'test/db/full_allele_overall_pass_download.csv'
  "#{Rails.configuration.htgt_root}/report/allele_overall_pass?view=csvdl"
end
