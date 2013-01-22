class DSpaceCSV
  def self.password_authorization(params)
    return nil unless (params["email"] && params["password"])
    Eperson.where(:email => params["email"], :password => Digest::MD5.hexdigest(params["password"])).first
  end

  def self.api_key_authorization(params, path)
    return nil unless (params[:api_key] && params[:api_digest])
    api_key = ApiKey.where(:public_key => params[:api_key]).first
    success = api_key && Digest::SHA1.hexdigest(path + api_key.private_key)[0..7] == params[:api_digest]
    success ? api_key.eperson : nil
  end

  def initialize(path, collection_id, user)
    @path = path
    @collection_id = collection_id
    @user = user
    get_instance_vars
  end

  def submit
    if @data[0] #real stuff 
      copy_submission_to_dspace
      import_submission
      copy_map_file_to_local
      cleanup
    else #fake stuff
      puts(@dspace_command)
    end
    @map_file
  end

  private
  
  def get_instance_vars
    @remote_path = File.join(DSpaceCSV::Conf.remote_tmp_dir, 'csv_' + @path.match(/(dspace_[\d]+)/)[1]) 
    @map_file = Time.now().to_s[0..18].gsub(/[\-\s]/,'_') + '_mapfile_' + @user.email.gsub(/[\.@]/, '_')
    @data = [DSpaceCSV::Conf.dspace_path, @user.email, @collection_id, @remote_path, File.join(DSpaceCSV::Conf.remote_tmp_dir, @map_file)]
    @dspace_command = "%s import ItemImport -a -e %s -c %s -s %s -m %s" % @data
    @local_mapfile_path = File.join(DSpaceCSV::Conf.root_path, 'public', 'map_files')
  end
 
  def copy_submission_to_dspace
    `scp -r #{@path} #{DSpaceCSV::Conf.remote_login}:#{@remote_path}`
  end
  
  def import_submission
    results = `ssh #{DSpaceCSV::Conf.remote_login} '#{@dspace_command}'` 
  end
    
  def copy_map_file_to_local
    `scp #{DSpaceCSV::Conf.remote_login}:#{File.join(DSpaceCSV::Conf.remote_tmp_dir, @map_file)} #{@local_mapfile_path}`
  end

  def cleanup
    `ssh #{DSpaceCSV::Conf.remote_login} 'find #{File.join(DSpaceCSV::Conf.remote_tmp_dir, "csv_dspace_*")} -maxdepth 0 -mtime 1 -exec rm -rf {} \;'`
  end

end
