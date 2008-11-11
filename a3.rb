require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'digest/md5'
require 'yaml'
require 'drb'

configure :development do
  SETTINGS = YAML.load_file 'settings.yml'
  Adhearsion = DRbObject.new_with_uri "druby://#{SETTINGS['drb_host']}:#{SETTINGS['drb_port']}"
  DataMapper.setup :default, "sqlite3://#{Dir.pwd}/db/a3.sqlite3"
end

configure :test do
    Adhearsion = DRbObject.new_with_uri "druby://#{SETTINGS['drb_host']}:#{SETTINGS['drb_port']}"
    DataMapper.setup :default, "sqlite3://#{Dir.pwd}/db/a3.test.sqlite3"
end

class User
  include DataMapper::Resource
  
  property :id,              Integer, :serial => true
  property :name,            String, :nullable => false
  property :extension,       String, :nullable => false
  property :trunk,           String, :nullable => false
  property :callerid_name,   String, :nullable => false
  property :callerid_number, String, :nullable => false
  property :password,        String, :nullable => false
  property :admin,           Boolean
end

DataMapper.auto_upgrade!

helpers do
  class AMI
    def self.call(caller, callee, callerid_number, callerid_name)
      args = { :channel => 'Local/s@a3-call/n', 
               :application => 'Dial', 
               :data => callee, 
               :caller_id => "#{callerid_name} <#{callerid_number}>", 
               :variable => "CALLER=#{caller}" }
      Adhearsion.proxy.originate args
    end
  end
end

get '/call/new' do
  @title = 'make a call - a3'
  @form = true
  haml :call_new
end

post '/call' do
  if @user = User.get(params[:id])
    if Digest::MD5.hexdigest(params[:password]) == @user.password
      @callee = @user.trunk + '/' + params[:callee]
      AMI.call @user.extension, @callee, @user.callerid_number, @user.callerid_name
    else
      throw :halt, [403, 'Invalid Password']
    end
  else
    throw :halt, [404, 'Invalid User']
  end
end

post '/user' do
  @user = User.new(:name             => params[:name], 
                   :extension        => params[:extension], 
                   :trunk            => params[:trunk],
                   :callerid_name    => params[:callerid_name],
                   :callerid_number  => params[:callerid_number],
                   :password         => Digest::MD5.hexdigest(params[:password]),
                   :admin            => params[:admin])
  if @user.save
    redirect "/user/#{@user.id}"
  else
    throw :halt, [500, 'Save Error']
  end
end

put '/user' do
  if @user = User.get(params[:id])
    if Digest::MD5.hexdigest(params[:password]) == @user.password
      @user.attributes = {:name            => params[:name], 
                          :extension       => params[:extension], 
                          :trunk           => params[:trunk],
                          :callerid_name   => params[:callerid_name],
                          :callerid_number => params[:callerid_number],
                          :password        => Digest::MD5.hexdigest(params[:new_password]),
                          :admin           => params[:admin]}
      if @user.save
        redirect "/user/#{@user.id}"
      else
        throw :halt, [500, 'Save Error']
      end
    else
      throw :halt, [403, 'Invalid Password']
    end
  else
    throw :halt, [404, 'Invalid User']
  end
end

delete '/user' do
  if @user = User.get(params[:id])
    if Digest::MD5.hexdigest(params[:password]) == User.first(:name => params[:name]).password
      if @user.destroy
        redirect '/user'
      else
        throw :halt, [500, 'Delete Error']
      end
    else
      throw :halt, [403, 'Invalid admin or password']
    end
  else
   throw :halt, [404, 'Invalid User']
  end
end

get '/user/new' do
  @title = 'new user - a3'
  @form = true
  haml :user_new
end

get '/user/:id' do
  if @user = User.get(params[:id])
    @title = "#{@user.name} - view user - a3"
    haml :user_show
  else
    throw :halt, [404, 'Invalid User']
  end
end

get '/user/:id/edit' do
  if @user = User.get(params[:id])
    @title = "#{@user.name} - edit user - a3"
    @form = true
    haml :user_edit
  else
    throw :halt, [404, 'Invalid User']
  end
end

get '/user/:id/delete' do
  if @user = User.get(params[:id])
    @title = "#{@user.name} - delete user - a3"
    @form = true
    haml :user_delete
  else
    throw :halt, [404, 'Invalid User']
  end
end

get '/res/form.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :form
end

