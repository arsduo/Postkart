GOOGLE_AUTH = YAML.load_file(File.join(Rails.root, "config", "google.yml"))[ENV["RACK_ENV"] || ENV["RAILS_ENV"]]
raise StandardError, "Missing Google key or secret for environment #{ENV["RACK_ENV"] || ENV["RAILS_ENV"]}" unless GOOGLE_AUTH && GOOGLE_AUTH["key"] && GOOGLE_AUTH["secret"]
