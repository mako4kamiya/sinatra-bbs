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
    profile_img = "default_user.png"
    password_digest = Digest::SHA512.hexdigest(password)
    client.exec_params("INSERT INTO users (name, email, password_digest, profile_img) VALUES ($1, $2, $3, $4)", [name, email, password_digest, profile_img])
    user = client.exec_params("SELECT * from users WHERE email = $1 AND password_digest = $2", [email, password_digest]).to_a.first
    session[:user] = user
    return redirect '/home'
end


get '/' do
    return erb :login
end

post '/login' do
    email = params[:email]
    password = params[:password]
    password_digest = Digest::SHA512.hexdigest(password)
    user = client.exec_params("SELECT * FROM users WHERE email = $1 AND password_digest = $2 LIMIT 1",[email, password_digest]).to_a.first
    if user.nil?
        return erb :login
    else
        session[:user] = user
        return redirect '/home'
    end
end

delete '/logout' do
    session[:user] = nil
    return redirect '/'
end

get '/home' do
    if session[:user].nil?
        return redirect '/'
    end
    @user =  client.exec_params("SELECT * FROM users WHERE id = $1",[session[:user]['id']]).to_a.first
    @chats = client.exec_params("SELECT * FROM chats JOIN users ON chats.user_id = users.id ORDER BY chats.id DESC").to_a
    @schedules = client.exec_params("SELECT * FROM schedules ORDER BY date").to_a
    # binding.pry
    return erb :home
end

post '/schedule_post' do
    subject = params[:subject]
    date = params[:date]
    session = params[:session]
    complement = params[:complement]
    published = 'on'
    client.exec_params("INSERT INTO schedules (subject, date, session, complement, published) VALUES ($1, $2, $3, $4, $5)",[subject, date, session, complement, published])
    redirect '/home'
end

delete '/schedule_delete/:id' do
    client.exec_params("DELETE FROM schedules WHERE id =$1",[params[:id]])
    redirect '/home'    
end

post '/chat_post' do
    user_id = session[:user]["id"]
    content = params[:content]
    client.exec_params("INSERT INTO chats (user_id, content) VALUES ($1, $2)",[user_id, content])
    redirect '/home'
end