SITE_PATH = case Rails.env
when 'production' then
  'http://www.sanger.ac.uk/kermits2'
when 'staging' then
  'http://htgt.internal.sanger.ac.uk:4008/kermits2'
else
  'http://example.com/kermits2'
end
