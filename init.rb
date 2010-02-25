# Include hook code here
require 'komerci'
#require 'acts_as_data_grid'
#ActiveRecord::Base.send(:include, Softa::DataGrid::Acts)
#ActionController::Base.send(:include, Softa::Uses::DataGrid)
#ActionController::Base.send(:include, Softa::DataGrid::Uses)

ActionView::Base.send(:include, Komerci::Helper)
# http://activerecord.rubyonrails.org/2007/2/4/new-feature-for-rails-2-0-multiple-controller-view-paths
ActionController::Base.view_paths.unshift File.join(directory, 'views')
