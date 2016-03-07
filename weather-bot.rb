require 'json'
require 'open-uri'
require 'slack/incoming/webhooks'

class WeatherBot
  def initialize
    @webhook_url = ENV['WEBHOOK_URL']
    @attachments = []
    @uri = 'http://weather.livedoor.com/forecast/webservice/json/v1?city=230010'
  end

  def temperature(weather, min_or_max)
    temperature = weather['temperature'][min_or_max]
    if temperature.nil?
      '---'
    else
      "#{temperature['celsius']}℃"
    end
  end

  def make_attachments_from_argument(today, tommorow, link)
    if ARGV[0].nil?
      append_attachment(today, link)
      append_attachment(tommorow, link)
    elsif ARGV[0] == 'today'
      append_attachment(today, link)
    elsif ARGV[0] == 'tommorow'
      @attachments[0]['text'] = ''
      append_attachment(tommorow, link)
    end
  end

  def append_attachment(weather, link)
    min = temperature(weather, 'min')
    max = temperature(weather, 'max')

    title = "#{weather['dateLabel']}の天気 「#{weather['telop']}」"
    text = "最高気温 #{max}\n最低気温 #{min}\n#{weather['date']}"

    attachment = {
      title: title,
      title_link: link,
      text: text,
      image_url: weather['image']['url'],
      color: '#7CD197'
    }
    @attachments.push(attachment)
  end

  def make_attachments
    res     = JSON.load(open(@uri).read)
    title   = res['title']
    text    = res['description']['text']
    link    = res['link']
    provider = res['copyright']['provider'].first['name']
    today = res['forecasts'][0]
    tommorow = res['forecasts'][1]

    @attachments.push({
      title: title,
      title_link: link,
      author_name: provider,
      text: text
    })
    make_attachments_from_argument(today, tommorow, link)
  end

  def post_weather_to_slack(text)
    slack = Slack::Incoming::Webhooks.new(@webhook_url, username: '天気')
    slack.post(text, attachments: @attachments)
  end
end

weather_bot = WeatherBot.new
weather_bot.make_attachments
weather_bot.post_weather_to_slack('')
