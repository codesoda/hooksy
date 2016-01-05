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

  if ENV['DEBUG']
    lines = []
    request.params.keys.each do |k|
      lines << "\n#{k} = #{request.params[k]}"
    end
    lines << "\n"
    lines << JSON.pretty_generate(request.env)
    message += "\n\n" + lines.join("\n")
  end

  Mail.deliver do
    from ENV['EMAIL_FROM']
    to ENV['EMAIL_TO']
    subject "SMS received from #{sender} to #{receipient}"
    body message
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