require 'slim'
require 'i18n'
require 'mysql2'
require 'sinatra/base'
require 'sinatra/activerecord'
require 'sinatra/partial'
require 'rack-flash'

class App < Sinatra::Base
 enable :sessions, :logging
 register Sinatra::Partial
 use Rack::MethodOverride
 use Rack::Flash, :accessorize => [:info, :error, :success], :sweep => true
 use Rack::Protection::AuthenticityToken # HTML forms now require: input name="authenticity_token" value=session[:csrf] type="hidden"
 set :public_folder, File.dirname(__FILE__) + '/public'
 set :views, File.dirname(__FILE__) + '/app/views'
 set :slim, :layout_engine => :slim, :layout => :'layouts/default', :pretty => true
 set :partial_template_engine, :slim
 set :session_secret, "25729f31a6bc7c57f8575db9b79ee468...." # SecureRandom.hex(128)

 helpers do
   def t(*args)
     ::I18n::t(*args)
   end
   def h(text)
     Rack::Utils.escape_html(text)
   end
   def authenticity_token
     %Q{<input type="hidden" name="authenticity_token" value="#{session[:csrf]}"/>}
   end
 end

 configure :development do
   require "sinatra/reloader"
   register Sinatra::Reloader
   also_reload '**/*.rb'
 end

 def debug_something_with_pry
   Kernel.binding.pry
 end
 
 get '/css/:name.css' do |name|
   headers 'Content-Type' => 'text/css; charset=utf-8'
   sass :"/css/#{name.to_s}"
 end

 get '/js/:name.js' do |name|
   content_type "text/javascript"
   coffee :"/js/#{name.to_s}"
 end

 error ActiveRecord::RecordNotFound do
   slim :'errors/404'
 end

 before do
   I18n.locale = params[:locale] || I18n.default_locale
 end
end

# Require attr_accessible...
ActiveRecord::Base.send(:attr_accessible, nil)

# Move to config/init/db.rb if you like
OpenStruct.new(YAML::load(File.open('config/database.yml'))[App.environment.to_s].symbolize_keys).tap do |config|
 ActiveRecord::Base.establish_connection(
   host: config.host,
   adapter: config.adapter,
   database: config.database,
   username: config.username,
   password: config.password
 )
end

%w(models controllers concerns).each do |name|
 Dir[File.join('app', name, '**/*.rb')].each do |file|
   require_relative file
 end
end

# Move to config/init/i18n.rb if you like
Dir[File.join(App.root, 'config', 'locales', '*.yml')].each do |file|
 I18n.backend.load_translations(file)
end
I18n.default_locale = :en

# Move to app/controllers/root_controller.rb
class RootController < App
 get '/' do
   flash[:notice] = "Thanks for nothing"
   slim :'index'
 end
end