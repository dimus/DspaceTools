require "fileutils"
require "bundler/setup"

require "sinatra"
require "erb"

get '/' do
    erb :index
end

post '/upload' do
    puts params.inspect
    params["file"][:tempfile].read
    erb :index
end

# load the csv into this csv
# do some sanity checks
# export
