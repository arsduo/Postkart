Rails.application.routes.routes.each do |r| 
  logger.debug({:name => r.name, :path => r.path}.inspect)
end