module RockerDocker
  module ConfigGenerator
    def self.configure
      puts "\nGenerating RockerDocker config file ...\n".yellow
      puts "  ==> #{Constants::ROCKER_DOCKER_CONFIG_FILE_NAME}".blue
      f = File.open(File.join(PATHS.current, Constants::ROCKER_DOCKER_CONFIG_FILE_NAME), 'w+')
      f.write(RockerDockerConfig.to_yaml_str)
      f.close
      puts
      0
    end

    def self.dockerize
      status = 0
      puts "\nGenerating config files ...\n".yellow
      status += create_config_directories
      status += create_config_files
      puts "\nDon't forget to update "\
        "\"#{Constants::CONFIG_DIRECTORY_NAME}/#{Constants::RAILS_DIRECTORY_NAME}/secrtes.yml\"".yellow.underline
      puts
      status
    end

    def self.undockerize
      puts "\nRemoving docker config files ...\n".yellow
      remove_config_directories
    end

    def self.rmdir(dir)
      FileUtils.rm_rf(File.join(PATHS.current, dir)) if File.directory?(File.join(PATHS.current, dir))
    end

    def self.remove_config_directories
      rmdir(Constants::CONFIG_DIRECTORY_NAME)
      FileUtils.rm_rf(Constants::DOCKERIGNORE_FILE_NAME)
      FileUtils.rm_rf(Constants::DOCKER_COMPOSE_FILE_NAME)
      0
    end

    def self.mkdir(dir)
      FileUtils.mkdir_p(File.join(PATHS.current, dir)) unless File.directory?(File.join(PATHS.current, dir))
    end

    def self.create_config_directories
      (Templates::ROOT_DIRECTORIES + Templates::RAILS_DIRECTORIES).each { |v| mkdir(v) }
      Templates::MYSQL_DIRECTORIES.each { |v| mkdir(v) } if RockerDockerConfig.databases.values.include? 'mysql'
      Templates::POSTGRES_DIRECTORIES.each { |v| mkdir(v) } if RockerDockerConfig.databases.values.include? 'postgresql'
      0
    end

    def self.create_custom_database_config
      puts "    ==> #{PATHS.relative_from_current(File.join(PATHS.rails_directory, 'database.yml'))}".blue
      f = File.open(File.join(PATHS.config_directory, Constants::RAILS_DIRECTORY_NAME, 'database.yml'), 'w+')
      f.write(ConfigLoader.app_config.to_yaml)
      f.close
      0
    end

    def self.create_rails_configs
      status = 0
      status += write_to_dir PATHS.rails_directory, Templates::RAILS_TEMPLATES, 'rails'
      status += create_custom_database_config
      status
    end

    def self.create_mysql_configs
      write_to_dir PATHS.mysql_directory, Templates::MYSQL_TEMPLATES, 'mysql'
    end

    def self.create_postgresql_configs
      write_to_dir PATHS.postgresql_directory, Templates::POSTGRES_TEMPLATES, 'postgresql'
    end

    def self.create_root_configs
      write_to_dir PATHS.current, Templates::ROOT_TEMPLATES
    end

    def self.create_config_files
      status = 0
      status += create_rails_configs
      status += create_mysql_configs if RockerDockerConfig.databases.values.include? 'mysql'
      status += create_postgresql_configs if RockerDockerConfig.databases.values.include? 'postgresql'
      status += create_root_configs
      status
    end

    def self.write_to_dir(dir, config_names, resource_name = '')
      config_names.each do |conf|
        puts "    ==> #{PATHS.relative_from_current(File.join(dir, conf).to_s)}".blue
        f = File.open(File.join(dir, conf), 'w+')
        f.write(
          StringIO.new(
            ERB.new(File.read(File.join(
                                PATHS.resources(resource_name),
                                "#{conf}.erb"
            ))).result(RockerDockerNameSpace.eval_i)
          ).read.gsub!(/\s*\n+/, "\n")
        )
        f.close
      end
      0
    end

    class << self
      private :rmdir
      private :remove_config_directories
      private :mkdir
      private :create_config_directories
      private :create_custom_database_config
      private :create_rails_configs
      private :create_mysql_configs
      private :create_postgresql_configs
      private :create_root_configs
      private :create_config_files
      private :write_to_dir
    end
  end
end
