require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'chronic'
require 'digest/sha1'
#require 'dm-migrations'
#require 'dm-aggregates'
require 'dm-postgres-adapter'

=begin

Ben Turner
Comm Lab Web, NYU-ITP 2011

NOTES:
To add new comparison objects, you'll have to add 2 entries to
the Records class (wins & losses), as well as a new entry in the
heads-up column below. Also you'll need to increment the
commented-out portion in app.rb that sets up the initial Records
entries.

=end

enable :sessions

APP_SECRET = "you are not your fucking khakis"  #this is the encryption key

#a defines the helper function #check_password!
=begin
helpers do 
  def #check_password!
    auth = Rack::Auth::Basic::Request.new(request.env)
    if auth.provided? && auth.basic? && auth.credentials
      user = User.first(:conditions => {:name => auth.credentials[0]})
    end
    
    if user && user.encrypted_password == Digest::SHA1.hexdigest(APP_SECRET + 
auth.credentials[1])
      session[:user_name] = user.name
      session[:user_id] = user.id
      return true
    else
      response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
      return false
    end
  end
end
=end

DataMapper::setup(:default, ENV['DATABASE_URL'] || 'sqlite3://my.db')

class User
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :encrypted_password, Text
  property :contact_email, String
  property :contact_phone, String
  property :contact_twitter, String
  property :contact_anonymous, String
  property :city, String
  property :state, String
  property :time_created, Time
  property :events_attended, Integer
  property :events_planned, Integer
  property :events_ditched, Integer

  has n, :userlinks
  has n, :events, :through => :userlinks
end

class Userlink
  include DataMapper::Resource

  property :id, Serial
  property :user_id, Integer
  property :name, String
  property :encrypted_password, Text
  property :contact_email, String
  property :contact_phone, String
  property :contact_twitter, String
  property :contact_anonymous, String
  property :city, String
  property :state, String
  property :time_created, Time
  property :events_attended, Integer
  property :events_planned, Integer
  property :events_ditched, Integer

  belongs_to :event, :key => true
  belongs_to :user, :key => true
end

# automatically create table
#User.auto_migrate! unless User.storage_exists?

class Event
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :neighborhood, String
  property :address, String
  property :city, String
  property :state, String
  property :activity, String
  property :author_id, Integer
  property :organizers, String
  property :location, String
  #property :attendees, String
  property :contact_list, String
  property :contact_email, String
  property :contact_phone, String
  property :contact_twitter, String
  property :contact_anonymous, String
  property :date, String
  property :time_list, String
  property :time_list_timestamp, Time
  property :time_created, String
  property :attendance, Integer
  property :occurred, String
  has n, :comments
  has n, :userlinks
  has n, :users, :through => :userlinks
end

#Event.auto_migrate! unless Event.storage_exists?

class EventLog
  include DataMapper::Resource
  property :id, Serial
  property :event_id, Integer
  property :feedback_user_id, Integer
  property :feedback, String
  property :review, Integer
end

#EventLog.auto_migrate! unless EventLog.storage_exists?

class Cities
  include DataMapper::Resource
  property :id, Serial
  property :name, String
  property :neighborhood, String
end

#City.auto_migrate! unless City.storage_exists?

class Comment
  include DataMapper::Resource
  property :id, Serial
  property :event_id, Integer
  property :name, String
  property :comment, Text
  property :time_posted, Time

  belongs_to :event
end

DataMapper.finalize
#DataMapper.auto_upgrade!
DataMapper.auto_migrate!


# from http://stackoverflow.com/questions/279769/convert-to-from-datetime-and-time-in-ruby
require 'date'
require 'time'
class Time
  def to_datetime
    # Convert seconds + microseconds into a fractional number of seconds
    seconds = sec + Rational(usec, 10**6)

    # Convert a UTC offset measured in minutes to one measured in a
    # fraction of a day.
    offset = Rational(utc_offset, 60 * 60 * 24)
    DateTime.new(year, month, day, hour, min, seconds, offset)
  end
end

$cities = ['New York', 'Washington, DC']
$neighborhoods_nyc = ['East Village', 'Chinatown', 'Chelsea', 'SoHo', 'Gramercy', 'Upper East Side', 'Upper West Side', 'Midtown', 'Lower East Side', 'Alphabet City', 'Harlem', 'Hell\'s Kitchen']
$activities = ['dancing', 'eating', 'drinking', 'hiking', 'a road trip', 'a concert', 'poker', 'a skill share', 'breakfast', 'lunch', 'dinner', 'brunch', 'other', 'food delivery']
$contact = ['email', 'phone', 'twitter']
$timeList = ['right now', 'tonight', 'today', 'tomorrow', 'this Friday', 'this Saturday', 'this Sunday', 'this weekend', 'next weekend']

# lets you connect initially via get, then post on subsequent pages
def get_or_post(path, opts={}, &block)
  get(path, opts, &block)
  post(path, opts, &block)
end

def array_or_string_for_javascript(option)
  if option.kind_of?(Array)
    "['#{option.join('\',\'')}']"
  elsif !option.nil?
    "'#{option}'"
  end
end

def header
header = "    <link type=\"text/css\" href=\"/css/start/jquery-ui-1.8.16.custom.css\" rel=\"Stylesheet\" />\n"
header += "  <link type=\"text/css\" href=\"/css/pg.css\" rel=\"Stylesheet\" />"
header += "    <script type=\"text/javascript\" src=\"/js/jquery-1.6.2.min.js\"></script>\n"
header += "    <script type=\"text/javascript\" src=\"/js/jquery-ui-1.8.16.custom.min.js\"></script>\n"
header += "    <link href=\"http://fonts.googleapis.com/css?family=Questrial\" rel=\"stylesheet\" type=\"text/css\">\n"
header
end

def toolbar
session[:user_id] = 1
session[:user_name] = "Ben Turner"

html = ""
html <<
"<DIV ID=\"toolbar\"><TABLE WIDTH=\"100%\" BORDER=0><TR><TD VALIGN=middle ALIGN=center CLASS=\"navButton\" ID=\"navAbout\"><A HREF=\"/about\">about</A></TD><TD VALIGN=middle ALIGN=center CLASS=\"navButton\" ID=\"navEvents\"><A HREF=\"/be\">events</A></TD><TD VALIGN=middle ALIGN=center CLASS=\"navButton\" ID=\"navPlan\"><A HREF=\"/plan\">plan event</A></TD><TD VALIGN=middle ALIGN=center CLASS=\"navButton\" ID=\"navUsers\"><A HREF=\"/user\">users</A></TD><TD VALIGN=middle ALIGN=center><A HREF=\"/\"><IMG SRC=\"/img/pg_logo.jpg\" WIDTH=356 HEIGHT=60 ALT=\"probablyGonna...\" TITLE=\"probablyGonna...\" BORDER=0 /></A></TD><TD VALIGN=middle ALIGN=right STYLE=\"font-size: smaller;\">"
if session[:user_id] != nil
html << "[ You're logged in as #{session[:user_name]}. ]<BR />[ <A HREF=\"/user/#{session[:user_id]}\" CLASS=\"user#{session[:user_id]}\">profile</A> | <A HREF=\"/logout\">logout</A> ]"
else
  html << "<FORM NAME=\"\" METHOD=\"post\" ACTION=\".\">[ Log in now. ]</FORM>"
end
html << "</TD></TR></TABLE></DIV><BR /><BR /><BR />"
html
end

# $toolbar = "<TABLE WIDTH=\"100%\" BORDER=0><TR><TD VALIGN=middle ALIGN=left><A HREF=\"/\"><STRONG>probablyGonna</STRONG></A> :: <A HREF=\"/about\">about</A> | <A HREF=\"/be\">events</A></TD><TD VALIGN=middle ALIGN=right>[ logged in as " +  "Ben Turner" + " ]</TD></TR></TABLE><BR /><BR />\n"

$footer = "<BR /><BR />\n<DIV STYLE=\"text-align: center; font-size: x-small;\">
created by <a href=\"http://benturner.com/\">ben turner</A> for his nyu-<A HREF=\"http://itp.nyu.edu/\">itp</A> comm lab web (prof: liesje hodgson) final project.
<BR /><a href=\"http://benturner.com/contact_me.php\">contact ben</a> with feedback.  made in ruby/sinatra.
</DIV>"

get '/plan' do
  #check_password!
  @cities = Cities.all(:name => "New York", :fields => [:neighborhood], :order => [:neighborhood.asc])
  erb :plan
end

# need to convert time to something usable
post '/plan/save' do
  #check_password!
  event = Event.new
  event.name = params[:name]
  event.city = params[:cityName]
  event.author_id = session[:user_id]
  event.organizers = session[:user_name]
  event.neighborhood = params[:neighborhood]
  event.activity = params[:activity]
  timeParams = Time.new
  t = timeParams.to_a
=begin
  case params[:timeList]
  when "right now"
    uts = Time.now
  when "tonight"
    uts = Time.local(t[5],t[4],t[3],20,0)
  when "today"
    uts = Time.local(t[5],t[4],t[3])
  when "tomorrow"
    uts = Time.local(t[5],t[4],t[3]+1)
  when "this Friday" || "this weekend"
    if t[6] == 6
      dayOffset = -1
    else
      dayOffset = t[6]
    end
    uts = Time.local(t[5],t[4],t[3]+5-dayOffset)
  when "this Saturday"
    uts = Time.local(t[5],t[4],t[3]+6-dayOffset)
  when "this Sunday"
    if t[6] == 6
      dayOffset = -1
    else
      dayOffset = t[6]
    end
    uts = Time.local(t[5],t[4],t[3]+7-dayOffset)
  when "next weekend"
    if t[6] == 6
      dayOffset = -1
    else
      dayOffset = t[6]
    end
    uts = Time.local(t[5],t[4],t[3]+11-dayOffset)
  else
  end
=end
  uts = Chronic.parse(params[:timeList])
  event.time_list_timestamp = uts
  event.time_list = params[:timeList]
  event.time_created = Time.now
  if params[:contactList] == nil
    event.contact_list = 'anonymous'
  else 
    event.contact_list = params[:contactList].join(", ")
  end
  $contact.each do |contact|
    eval("event.contact_" + contact + " = params[:contact_" + contact + "]")
  end
  event.save

  output = "Your event's been posted!"
  output
end

post '/be/addcomment' do
  #check_password!
  event = Event.get(params[:event_id])
  comment = Comment.new
  comment.name = session[:user_name]
  comment.comment = params[:comment]
  comment.time_posted = Time.now
  event.comments << comment
  event.save
  comment.save

  output = "Your comment was posted."
  output
end

get '/be' do
  #check_password!
  @event = Event.all(:city => 'New York')
  @eventsNowStart = Chronic.parse('right now')-1800
  @eventsNowEnd = Chronic.parse('right now')+1800
  @eventsRightNow = Event.all(:time_list_timestamp => @eventsNowStart..@eventsNowEnd)
  @eventsToday = Event.all(:time_list_timestamp => Chronic.parse('today'))
  @title = "probablyGonna be doing some stuff"
  erb :be
end

get '/be/in' do
  redirect to '/be'
end

get '/be/in/:city' do
  #check_password!
  testCities = Cities.all
  if ($cities.include? params[:city])
    @title = "probablyGonna be in " + params[:city]
    @event = Event.all(:city => params[:city])
  else
    for city in $cities do
      testCities2 = Cities.all(:name => city)
      testHood = Cities.all(:neighborhood => params[:city])
      if testHood.length != 0
        @title = "probablyGonna be in " + params[:city]
        @event = Event.all(:neighborhood => params[:city])
      else
        @title = "probablyGonna be in New York"
        @event = Event.all(:city => 'New York')
      end
    end
  end

  @eventsNowStart = Chronic.parse('right now')-1800
  @eventsNowEnd = Chronic.parse('right now')+1800
  @eventsRightNow = Event.all(:time_list_timestamp => @eventsNowStart..@eventsNowEnd)
  @eventsToday = Event.all(:time_list_timestamp => Chronic.parse('today'))
  erb :be
end

get '/be/doing' do
  redirect to '/be'
end

get '/be/doing/:activity' do
  #check_password!
  if ($activities.include? params[:activity])
    @title = "probablyGonna be " + params[:activity]
    @event = Event.all(:activity => params[:activity])
  else
    @title = "probablyGonna be doing something"
    @event = Event.all(:activity => params[:activity])
  end

  @eventsNowStart = Chronic.parse('right now')-1800
  @eventsNowEnd = Chronic.parse('right now')+1800
  @eventsRightNow = Event.all(:time_list_timestamp => @eventsNowStart..@eventsNowEnd)
  @eventsToday = Event.all(:time_list_timestamp => Chronic.parse('today'))
  erb :be
end

get '/be/on' do
  redirect to '/be'
end

get '/be/on/:date' do
  #check_password!
  @title = "probablyGonna be on " + params[:date]
  @event = Event.all(:time_list_timestamp => Chronic.parse(params[:date], :guess => false))

  @eventsNowStart = Chronic.parse('right now')-1800
  @eventsNowEnd = Chronic.parse('right now')+1800
  @eventsRightNow = Event.all(:time_list_timestamp => @eventsNowStart..@eventsNowEnd)

  @eventsToday = Event.all(:time_list => Chronic.parse('today'))
  #@eventsToday = Event.all(:time_list.gt => Chronic.parse('12 in the morning'), :time_list.lt => Chronic.parse('11:59 in the evening'))
  erb :be
end

get '/be/attending' do
  redirect to '/be'
end

get '/be/attending/:eventID' do
  #check_password!
  @event = Event.get(params[:eventID])

  if userlinks(:user_id => session[:user_id]) == nil
    usertemp = User.get(session[:user_id])
    user = Userlink.new
    user.user_id = usertemp.id
    output = "You're now attending the event."
  elsif userlinks(:user_id => session[:user_id]) != nil
    userlinks = Userlink.all
    user = userlinks(:user_id => session[:user_id])
    user.destroy
    output = "You're no longer attending the event."
  end
  user.save
  output
end

get '/register' do
  erb :register
end

post '/register/save' do
user = User.new
  user.name = params[:user_name]
  user.encrypted_password = Digest::SHA1.hexdigest(APP_SECRET + params[:password])
  user.time_created = Time.now
  user.save
  
  redirect to "/be"
end

get '/login' do
  ##check_password!
  #redirect to '/be'
  erb :login
end

post '/login/check' do
  if params[:user_name] != nil && params[:password] != nil
    user = User.first(:conditions => {:name => params[:user_name]})
  end
    
  if user && user.encrypted_password == Digest::SHA1.hexdigest(APP_SECRET + params[:password])
    output = "You are now logged in."
    session[:user_name] = params[:user_name]
    getID = User.first(:conditions => {:name => params[:user_name]})
    session[:user_id] = getID.id
    redirect to '/be'
  else
    response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
    throw(redirect to '/register')
  end
  output
end

get '/logout' do
  session[:user_id] = nil
  session.clear
  output = "You have successfully logged out." 
  output
end

get '/user' do
  @user = User.all
  erb :userlist
end

get '/user/:userID' do
  #check_password!

  if User.get(params[:userID]) != nil
    @user = User.get(params[:userID])
  else
    redirect to '/user'
  end
  erb :user
end

get '/admin' do
  #check_password!
  erb :admin
end

get '/' do
  #check_password!
  redirect to '/register'
end

get '/about' do
  #check_password!
  erb :about
end

get '/seed_db' do
  # run once to set records!
  user = User.new
  user.name = Ben Turner
  user.encrypted_password = "4442fa7b606dd57759110f4940f1ab0586074cdd"
  user.time_created = "2011-12-14 11:31:43.938206 -05:00"
  user.save
end

get_or_post '/add_neighborhood' do

  #check_password!

  # Only if someone POSTed.
  if (params[:posted] == "true")
    @cityAdd = Cities.new
    @cityAdd.attributes = { :name => params[:cityName], :neighborhood => params[:neighborhood] }
    @cityAdd.save

    @output = "[This neighborhood has been saved!  Add another?]<BR /><BR />\n"
  end

  erb :add_neighborhood
end