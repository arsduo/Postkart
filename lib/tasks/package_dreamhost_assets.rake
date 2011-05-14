require 'action_controller' # gotcha
require 'jammit'

module Jammit
  class Packager
    
    def pack_stylesheets_reliably(*args)
      pack_reliably { pack_stylesheets_unreliably(*args) }
    end
    
    def pack_javascripts_reliably(*args)
      pack_reliably { pack_javascripts_unreliably(*args) }
    end
    
    alias_method :pack_stylesheets_unreliably, :pack_stylesheets
    alias_method :pack_stylesheets, :pack_stylesheets_reliably
    alias_method :pack_javascripts_unreliably, :pack_javascripts
    alias_method :pack_javascripts, :pack_javascripts_reliably
    
    def pack_reliably(&pack_action)
      content = ""
      while content.length == 0
        begin
          content = pack_action.call
        rescue StandardError => err
          puts "Retrying past #{err.class}: #{err.message}"
          retry # risk 2
        end
      end
      content
    end
  end
end

desc "Uses Jammit to rebuild packages, ensuring they get built despite Dreamhost's automated process killing."
namespace :jammit do
  task :package_dreamhost_assets do
    Jammit::Packager.new.precache_all
  end
end