
require 'sinatra'
require 'sinatra/reloader'

get '/hello' do
    return erb :hello
end