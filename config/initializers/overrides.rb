unless Rails.env.development?
  Rake::Task["db:structure:dump"].clear
end