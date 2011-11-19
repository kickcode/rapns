class RapnsGenerator < Rails::Generators::Base
  include Rails::Generators::Migration
  source_root File.expand_path('../templates', __FILE__)

  def copy_config
    copy_file "rapns.yml", "config/rapns/rapns.yml"
  end
end
