require 'sinatra'
require 'sinatra/reloader'
require 'pg'
require 'pry'
require "fileutils"
require 'digest'

enable :sessions

client = PG::connect(
    :host => ENV.fetch("DB_HOST", "localhost"),
    :user => ENV.fetch("DB_USER","postgres"),
    :password => ENV.fetch("DB_PASSWORD",""),
    :dbname => ENV.fetch("DB_NAME")
)

get '/signup' do
    return erb :signup
  end
  
  post '/signup' do
    name = params[:name]
    email = params[:email]
    password = params[:password]
    password_digest = Digest::SHA512.hexdigest(password)
    client.exec_params("INSERT INTO users (name, email, password) VALUES ($1, $2, $3)", [name, email, password_digest])
    user = client.exec_params("SELECT * from users WHERE email = $1 AND password = $2", [email, password_digest]).to_a.first
    session[:user] = user
    return redirect '/posts'
  end
  

get '/login' do
    return erb :login
end

post '/login' do
    email = params[:email]
    password = params[:password]
    password_digest = Digest::SHA512.hexdigest(password)
    user = client.exec_params("SELECT * FROM users WHERE email = $1 AND password = $2 LIMIT 1",[email, password_digest]).to_a.first
    if user.nil?
        return erb :login
    else
        session[:user] = user
        return redirect '/posts'
    end
end

delete '/logout' do
    session[:user] = nil
    return redirect '/login'
end

get '/posts' do
    if session[:user].nil?
        return redirect '/login'
    end
    @posts = client.exec_params("SELECT * from posts").to_a
    return erb :posts
end

post '/posts' do
    user_id = session[:user]["id"]
    name = params[:name]
    content = params[:content]
    # binding.pry
    image_name = ''
    if !params[:image].nil? # データがあれば処理を続行する
        tempfile = params[:image][:tempfile] # ファイルがアップロードされた場所
        save_to = "./public/images/#{params[:image][:filename]}" # ファイルを保存したい場所
        FileUtils.mv(tempfile, save_to)
        image_name = params[:image][:filename]
    end
    client.exec_params("INSERT INTO posts (user_id, content, image_path) VALUES ($1, $2, $3)",[user_id, content, image_name])
    redirect '/posts'
end