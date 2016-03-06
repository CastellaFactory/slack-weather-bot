require 'json'
require 'open-uri'
require 'slack/incoming/webhooks'

def post_to_slack(text, attachments)
  slack = Slack::Incoming::Webhooks.new ENV['WEBHOOK_URL']
  slack.post text, attachments
end

def temperature(weather, min_or_max)
  temperature = weather['temperature'][min_or_max]
  if temperature.nil?
    '---'
  else
    "#{temperature['celsius']}℃"
  end
end

def post_weather(weather, link)
  min = temperature weather, 'min'
  max = temperature weather, 'max'

  title = "#{weather['dateLabel']}の天気 「#{weather['telop']}」"
  text = "最高気温 #{max}\n最低気温 #{min}\n#{weather['date']}"
  
  attachments = [{
    title: title,
    title_link: link,
    text: text,
    image_url: weather['image']['url'],
    color: '#7CD197'
  }]

  post_to_slack '', attachments: attachments
end

uri = 'http://weather.livedoor.com/forecast/webservice/json/v1?city=230010'

res     = JSON.load(open(uri).read)
title   = res['title']
text    = res['description']['text']
link    = res['link']
provider = res['copyright']['provider'].first['name']
today = res['forecasts'][0]
tommorow = res['forecasts'][1]

attachments = [{
  title: title,
  title_link: link,
  author_name: provider,
  text: text
}]

post_to_slack '', attachments: attachments
post_weather today, link
post_weather tommorow, link
