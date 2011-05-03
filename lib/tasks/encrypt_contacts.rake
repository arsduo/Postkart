desc "Removes the addresses column, moving it over to the encrypted version"
namespace :postkart do
  task :encrypt_addresses => :environment do
    Contact.all.each do |c|
      # encrypt all addresses and remove the unencrypted ones from the DB
      c.addresses = c["addresses"]
      c["addresses"] = nil
      c.save!
    end 
  end
end