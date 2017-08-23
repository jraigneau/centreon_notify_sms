#!/usr/bin/env ruby

require 'yaml'
require 'optparse'
require 'optparse/time'
require 'net/smtp'
require 'net/http'
require 'json'
require 'uri'


# Parse the options
options = Hash.new
options[:config] = nil
options[:mode] = nil
options[:hostname] = nil
options[:time] = nil
options[:service] = nil
options[:type] = nil
options[:state] = nil
options[:phone_number] = nil
options[:details] = nil
options[:dont_send_sms] = false

opts = OptionParser.new do |opts|
  opts.banner = 'Usage: centreon_notify_sms.rb [options]'
  opts.separator ''
  opts.separator 'Options :'

  opts.on('-c', '--config=PATH', 'Path to the config file') do |config|
    options[:config] = config
  end

  opts.on('-m', '--mode=MODE', [:host, :service], 'Select alert object type (service, host)') do |mode|
    options[:mode] = mode
  end

  opts.on('-h', '--hostname=HOSTNAME', 'Hostname for which the event occurs') do |hostname|
    options[:hostname] = hostname
  end

  opts.on('-d', '--time=HH:MM:SS', Time, "Time of the event") do |time|
    options[:time] = time
  end

  opts.on('-s', '--service=SERVICE', 'Service from which the event occurs' , 'Only on service mode') do |service|
    options[:service] = service
  end

  opts.on('-t', '--type=TYPE', 'Event type') do |type|
    options[:type] = type
  end

  opts.on('-a', '--state=STATE', 'State of the service/host') do |state|
    options[:state] = state
  end

  opts.on('-e', '--details=DETAILS', 'Details about the alert (url)') do |details|
    options[:details] = details
  end

  opts.on('-n', '--phone=PHONE', 'Phone number to send the message') do |phone|
    options[:phone_number] = phone
  end

  opts.on_tail('-h', '--help', 'Show this message') do
    puts opts
    exit
  end
end

begin
  opts.parse!(ARGV)
rescue OptionParser::ParseError => e
  abort e.message+"\nTry --help for a list of options"
end

# Check if all arguments are here
class MissingArg < Exception
end
begin
  raise MissingArg, 'You must specify a config file' if options[:config] == nil
  raise MissingArg, 'You must choose a mode' if options[:mode] == nil
  raise MissingArg, 'You must specify a hostname' if options[:hostname] == nil
  raise MissingArg, 'You must specify a time' if options[:time] == nil
  raise MissingArg, 'You must specify an event type' if options[:type] == nil
  raise MissingArg, 'You must specify a state' if options[:type] == nil
  raise MissingArg, 'You must speficy a phone number' if options[:phone_number] == nil

  if options[:mode] == :service
    raise MissingArg, 'You most specity a service name' if options[:service] == nil
  end
rescue MissingArg => e
  abort 'Error : '+e.message+"\nTry --help for a list of options"
end

# Load the config file
config = YAML.load_file(options[:config])

type = options[:type]
state = options[:state]
hostname = options[:hostname]
service = options[:service]
time = options[:time]
details = options[:details]
phone_number = options[:phone_number]
cleaned_phone = phone_number.gsub("+","")


#Replace terms to be user-friendly
if config['replace']
  state = config['replace']['state'][state] if config['replace']['state'] and config['replace']['state'][state]
end


#Build message
if type == "PROBLEM"
  message = "<DATA><MESSAGE><![CDATA[Alerte #{state} sur #{hostname}/#{service}@#{time.hour}:#{time.min} #{details}]]></MESSAGE><TPOA>SUP iDNA</TPOA><SMS><MOBILEPHONE>#{phone_number}</MOBILEPHONE></SMS></DATA>"
elsif type == "RECOVERY"
  message = "<DATA><MESSAGE><![CDATA[Fin d'alerte #{state} sur #{hostname}/#{service}@#{time.hour}:#{time.min} #{details}]]></MESSAGE><TPOA>SUP iDNA</TPOA><SMS><MOBILEPHONE>#{phone_number}</MOBILEPHONE></SMS></DATA>"
elsif condition
  message = "<DATA><MESSAGE><![CDATA[#{type} #{state} sur #{hostname}/#{service}@#{time.hour}:#{time.min} #{details}]]></MESSAGE><TPOA>SUP iDNA</TPOA><SMS><MOBILEPHONE>#{phone_number}</MOBILEPHONE></SMS></DATA>"
end

#get Credentials
login = config['account']['login']
api = config['account']['api']

#prepare and Send request
url = URI.parse('https://api.allmysms.com/http/9.0/sendSms/')
req = Net::HTTP::Post.new(url.path)
req.set_form_data({'login'=>login,'apiKey'=>api,'smsData'=>message}, '&')
http = Net::HTTP.new(url.host, url.port)
http.use_ssl = true
res = http.start {|http| http.request(req) }

#Debug ....
#puts message

#puts res.code       # => '200'
#puts res.message    # => 'OK'
#puts res.class.name # => 'HTTPOK'

#puts res.body
