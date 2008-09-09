require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'digest/md5'
require "yaml"
require 'drb'

configure do
  SETTINGS = YAML::load(File.open("settings.yml"))
  Adhearsion = DRbObject.new_with_uri "druby://#{SETTINGS['drb_host']}:#{SETTINGS['drb_port']}"
  DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/a3.sqlite3")
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

get '/call' do
  haml :call
end

post '/call' do
  @user = User.get(params[:id])
  if Digest::MD5.hexdigest(params[:password]) == @user.password
    @callee = @user.trunk + "/" + params[:callee]
    
    AMI.call @user.extension, @callee, @user.callerid_number, @user.callerid_name
  else
    throw :halt, [403, 'Invalid Password']
  end    
end

post '/user' do
  @user = User.new(:name            => params[:name], 
                  :extension        => params[:extension], 
                  :trunk            => params[:trunk],
                  :callerid_name    => params[:callerid_name],
                  :callerid_number  => params[:callerid_number],
                  :password         => Digest::MD5.hexdigest(params[:password]))
  if @user.save
    redirect "/user/#{@user.id}"
  else
    redirect '/'
  end
end

get '/user/add' do
  haml :user_add
end

get '/user/:id' do
  @user = User.get(params[:id])
  if @user
    haml :user_show
  else
    redirect '/'
  end
end
