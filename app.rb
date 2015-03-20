require 'rubygems'
require 'bundler'
Bundler.setup
Bundler.require :default

$users = {}

OPENID_FIELDS = {
  google: ["http://axschema.org/contact/email", "http://axschema.org/namePerson/last"],
  geni: ['http://geni.net/projects', 'http://geni.net/slices', 'http://geni.net/user/urn', 'http://geni.net/user/prettyname']
}

Warden::OpenID.configure do |config|
  puts "config.....!config.....!config.....!config.....!config.....!"
  config.required_fields = OPENID_FIELDS[:geni]
  config.user_finder do |response|
    #fields = OpenID::SReg::Response.from_success_response(response)
    identity_url = response.identity_url
    fields = OpenID::AX::FetchResponse.from_success_response(response).data
    $users[identity_url] = fields
    identity_url
  end
end

helpers do
  def warden
    env['warden']
  end
end

get '/' do
p "fdfdfd....!"

if !$users[warden.user].nil?
p @x= $users[warden.user]["http://geni.net/user/prettyname"]
p @x[0]
redirect 'http://'+request.host+':3000/models'+'?login='+@x[0]
end

p "fdfdfd....!"

  haml <<-'HAML'
%p#notice= flash[:notice]
%p#error= flash[:error]


- if warden.authenticated?

  - p $users[warden.user]
  %p
    Welcome #{warden.user}!
    %a(href='/signout') Sign out
  %hr
    - $users[warden.user] && $users[warden.user].each do |k, v|
      %p
        #{k}: #{v}
- else
    HAML
    erb :index
  
    
end

post '/signin' do
  puts "signinsigninsigninsigninsigninsigninsigninsigninsignin"

  p $users[warden.user]
  puts "signinsigninsigninsigninsigninsigninsigninsigninsignin"

  warden.authenticate!
  

  #redirect 'http://localhost:3000' + request.fullpath
  flash[:notice] = 'You signed in'
  redirect '/'
end
get '/about' do
  erb :about

end


get '/contact' do
  erb :contact

end




get '/signout' do
  puts "signoutsignoutsignoutsignoutsignoutsignoutsignout.....!"
  warden.logout(:default)
  flash[:notice] = 'You signed out'
  redirect '/'
end

post '/unauthenticated' do

  puts "unauthenticatedunauthenticatedunauthenticatedunauthenticatedunauthenticatedunauthenticated"
  if openid = env['warden.options'][:openid]
    # OpenID authenticate success, but user is missing
    # (Warden::OpenID.user_finder returns nil)
    session[:identity_url] = openid[:response].identity_url
    name = "Authenticated user via #{session[:identity_url]}"
    fields = OpenID::SReg::Response.from_success_response(openid[:response])
    u = fields.data
    $users[session.delete(:identity_url)] = u
    u[:junk] = (1..100000).map { "bob" }
    warden.set_user u
    redirect '/'
  else
    # OpenID authenticate failure
    flash[:error] = warden.message
    redirect '/'
  end
end

get '/register' do
  haml <<-'HAML'
%form(action='/signup' method='post')
  %p
    %label
      Name:
      %input(type='text' name='name')
    %input(type='submit' value='Sign up')
  HAML
end

post '/signup' do
  if (name = params[:name]).empty?
    redirect '/register'
  else
    $users[session.delete(:identity_url)] = name
    warden.set_user name
    flash[:notice] = 'You signed up'
    redirect '/'
  end
end

require 'rubygems'
require 'sinatra'

get '/' do
  erb :index
end
