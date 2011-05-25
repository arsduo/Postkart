desc "Removes the addresses column, moving it over to the encrypted version"
namespace :postkart do
  task :compile_trip_mailings => :environment do
    # MongoDB streams this, so we can write it so
    Trip.all.each do |t|      
      t.recipients = Mailing.where(:trip_id => t._id).collect {|m| m.contact_id}
      t.save
    end
  end
end