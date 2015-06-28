require 'active_support/core_ext/module/attribute_accessors'

require 'rails_config/options'
require 'rails_config/version'
require 'rails_config/engine' if defined?(::Rails)
require 'rails_config/sources/yaml_source'
require 'deep_merge'

module RailsConfig
  # ensures the setup only gets run once
  @@_ran_once = false

  mattr_accessor :const_name, :use_env, :overwrite_arrays
  @@const_name = "Settings"
  @@use_env = false
  @@overwrite_arrays = true

  def self.setup
    yield self if @@_ran_once == false
    @@_ran_once = true
  end

  # Create a populated Options instance from a yaml file. If a second yaml file is given, then the sections of that
  # file will overwrite existing sections of the first file.
  def self.load_files(*files)
    config = Options.new
    config.overwrite_arrays = overwrite_arrays

    # add yaml sources
    [files].flatten.compact.uniq.each do |file|
      config.add_source!(file.to_s)
    end

    config.load!
    config.load_env! if @@use_env
    config
  end

  # Loads and sets the settings constant!
  def self.load_and_set_settings(*files)
    Kernel.send(:remove_const, RailsConfig.const_name) if Kernel.const_defined?(RailsConfig.const_name)
    Kernel.const_set(RailsConfig.const_name, RailsConfig.load_files(files))
  end

  def self.setting_files(config_root, env)
    [
      File.join(config_root, "settings.yml").to_s,
      File.join(config_root, "settings", "#{env}.yml").to_s,
      File.join(config_root, "environments", "#{env}.yml").to_s,

      File.join(config_root, "settings.local.yml").to_s,
      File.join(config_root, "settings", "#{env}.local.yml").to_s,
      File.join(config_root, "environments", "#{env}.local.yml").to_s
    ].freeze
  end

  def self.reload!
    Kernel.const_get(RailsConfig.const_name).reload!
  end
end

# add rails integration
require('rails_config/integration/rails') if defined?(::Rails)

# add sinatra integration
require('rails_config/integration/sinatra') if defined?(::Sinatra)
