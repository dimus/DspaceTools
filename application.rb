#!/usr/bin/env ruby
require 'rack/timeout'
require 'sinatra'
require 'sinatra/basic_auth'
require 'sinatra/base'
require 'sinatra/flash'
require 'sinatra/redirect_with_flash'
require_relative "./environment"


class DSpaceCsvGui < Sinatra::Base
  mime_type :csv, 'application/csv'
  register Sinatra::Flash
  register Sinatra::BasicAuth
  helpers Sinatra::RedirectWithFlash
  
  enable :sessions

  use Rack::Timeout
  Rack::Timeout.timeout = 9_000_000

  helpers do 
    include Sinatra::RedirectWithFlash
    include Rack::Utils

    alias_method :h, :escape_html
    
    def get_dir_structure(dir)
      res = []
      Dir.entries(dir).each do |e|
        if e.match /^[\d]{4}/
          res << [e, get_dir_content(File.join(dir, e))]
        end
      end
      res
    end

    private

    def get_dir_content(dir)
      res = []
      Dir.entries(dir).each do |e|
        next if e.match /^[\.]{1,2}$/
        res << [e, '']
        if ['contents', 'dublin_core.xml'].include?(e)
          res[-1][1] = open(File.join(dir, e), "r:utf-8").read
        end
      end
      res
    end
  end

  def api_authorization(params)
    return nil unless (params["email"] && params["password"])
    Eperson.where(:email => params["email"], :password => Digest::MD5.hexdigest(params["password"])).first
  end


  ###########################################################################
  #  API
  ###########################################################################

  get '/rest/users.?:format?' do
    current_user = api_authorization(params)
    if current_user
      if params["format"] == "xml"
        content_type 'text/xml', :charset => 'utf-8'
      elsif params["format"] == "json"
        content_type 'application/json', :charset => 'utf-8'
      else
        content_type 'text/plain', :charset => 'utf-8'
      end
      RestClient.get(DSpaceCSV::Conf.dspace_repo + request.env["REQUEST_PATH"], params)
    else
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  protect  do
    get '/' do
        session[:current_user] = DSpaceCSV::Conf.users[auth.credentials.first]
        haml :index
    end

    get '/formatting-rules' do
        erb :rules
    end

    get '/stsrepository-instructions' do
        erb :sts
    end

    get '/extra-help' do
        erb :help
    end

    get 'template.csv' do
        content_type :csv
        send_file 'template.csv'
    end

    post '/upload' do
      begin
        DSpaceCSV::Uploader.clean(1)
        u = DSpaceCSV::Uploader.new(params)
        e = DSpaceCSV::Expander.new(u)
        t = DSpaceCSV::Transformer.new(e)
        if t.errors.empty?
          session[:path] = t.path
          session[:collection_id] = params["collection_id"]
          redirect '/upload_result', :warning => t.warnings[0]
        else
          redirect "/", :error => t.errors.join("<br/>")
        end
      rescue DSpaceCSV::CsvError => e
        redirect "/", :error => e.message 
      rescue DSpaceCSV::UploadError => e
        redirect "/", :error => e.message 
      end
    end

    post '/submit' do
      @map_file = DSpaceCSV.submit(session[:path], session["collection_id"], session["current_user"])
      redirect '/upload_finished?map_file=' + URI.encode(@map_file)
    end

    get '/upload_result' do
      haml :upload_result
    end

    get '/upload_finished' do
      @map_file = params["map_file"]
      haml :upload_finished
    end
  end

  authorize do |username, password|
    DSpaceCSV.authenticate(username, password)
  end

  run! if app_file == $0

end

