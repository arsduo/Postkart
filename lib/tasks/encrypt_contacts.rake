desc "Removes the addresses column, moving it over to the encrypted version"
namespace :postkart do
  task :encrypt_addresses => :environment do
    Contact.all.each do |c|
      addr = c["addresses"]
      c.addresses = c["addresses"]
      c["addresses"] = nil
      puts "Now: #{c.encrypted_addresses} => #{c.addresses}"
      c["addresses"] = addr
    end 
  end
end