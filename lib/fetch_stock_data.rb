require 'httparty'
require 'csv'
require 'json'
require 'date'
require 'concurrent'
require 'dotenv'

Dotenv.load

API_KEY = ENV['ALPHA_VANTAGE_API_KEY']
SYMBOLS = ["AAPL", "GOOGL", "MSFT", "AMZN", "FB"]

def fetch_stock_data(symbol)
  url = "https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol=#{symbol}&outputsize=full&apikey=#{API_KEY}"
  response = HTTParty.get(url)
  data = JSON.parse(response.body)

  unless data.key?("Time Series (Daily)")
    puts "Fail to fetch data: #{symbol}"
    return nil
  end

  daily_data = data["Time Series (Daily)"].map do |date, values|
    [
      date,
      symbol,
      values["1. open"],
      values["2. high"],
      values["3. low"],
      values["4. close"],
      values["5. volume"]
    ]
  end

  daily_data.sort_by! { |row| Date.parse(row[0]) }.reverse!
  daily_data
end

def fetch_all_stocks(symbols)
  all_data = Concurrent::Array.new

  Concurrent::Promise.zip(*symbols.map { |symbol|
    Concurrent::Promise.execute do
      data = fetch_stock_data(symbol)
      if data
        all_data.concat(data)
        puts "Fetched #{symbol}"
      end
      sleep 12
    end
  }).wait

  all_data
end

result = fetch_all_stocks(SYMBOLS)

CSV.open("stock_data.csv", "wb") do |csv|
  csv << ["date", "symbol", "open", "high", "low", "close", "volume"]
  result.each { |row| csv << row }
end

puts "Fetched Data Completely!"