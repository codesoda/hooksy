require 'rubygems'
require 'bundler'


Bundler.require

disable :protection

set :root, File.dirname(__FILE__)

configure :development do
  Mail.defaults do
    delivery_method :smtp, address: 'localhost', port: 1025
  end
end

configure :production do
  Mail.defaults do
    delivery_method :smtp,
                    address: ENV['SMTP_SERVER'],
                    port: 587,
                    user_name: ENV['SMTP_USERNAME'],
                    password: ENV['SMTP_PASSWORD'],
                    authentication: 'plain',
                    enable_starttls_auto: true
  end
end

get '/' do
  # [200, {}, 'OK']
  [200, { 'SERVER' => 'HOOKSY & CAFFEINE' }, 'OK']
end

post '/twilio/mailer' do
  sender = params['From']
  receipient = params['To']
  message = params['Body']
  subject = "SMS received from #{sender} to #{receipient}"

  if ENV['DEBUG']
    lines = []
    request.params.keys.each do |k|
      lines << "\n#{k} = #{request.params[k]}"
    end
    lines << "\n"
    lines << JSON.pretty_generate(request.env)
    message += "\n\n" + lines.join("\n")
  end

  channels = ENV.fetch('CHANNELS', '').split(',')

  if channels.include?('EMAIL')
    Mail.deliver do
      from ENV['EMAIL_FROM']
      to ENV['EMAIL_TO']
      subject subject
      body message
    end
  end

  if channels.include?('SLACK')
    Slack.configure { |config| config.token = ENV['SLACK_API_TOKEN'] }
    client = Slack::Web::Client.new
    client.chat_postMessage(channel: ENV['SLACK_CHANNEL'], text: "#{subject}: #{message}", as_user: true)
  end

  [
    200,
    {
      'SERVER' => 'HOOKSY & CAFFEINE',
      'Content-type' => 'text/xml'
    },
    '<Response></Response>'
  ]
end
