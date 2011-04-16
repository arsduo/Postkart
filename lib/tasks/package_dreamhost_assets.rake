require 'action_controller' # gotcha
require 'jammit'
 
desc "Uses Jammit to rebuild packages, ensuring they get built despite Dreamhost's automated process killing."
namespace :jammit do
  task :package_dreamhost_assets do
    j = Jammit::Packager.new
    outputdir = File.join(Jammit::PUBLIC_ROOT, Jammit.package_path)
    packages = j.instance_variable_get(:@packages) # risk 1

    packages.each_key do |genera|
      puts "Packaging #{packages[genera].keys.length} #{genera.to_s} packages."

      packages[genera].each_key do |group| # note
        content = ""
        while content.length == 0 do
          begin
            content = (genera == :js ? j.pack_javascripts(group) : j.pack_stylesheets(group))
          rescue Exception => err
            puts "Retrying past error: #{err.message}"
            retry # risk 2
          end
        end
        j.cache(group, genera.to_s, content, outputdir)
      end
    end
  end
end