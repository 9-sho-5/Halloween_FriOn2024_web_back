require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require './models.rb'
require 'pry'

# Enable CORS
before do
  response.headers['Access-Control-Allow-Origin'] = '*'
  response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
  response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
end

# Handle OPTIONS requests
options '*' do
  response.headers['Access-Control-Allow-Origin'] = '*'
  response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
  response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
  200
end

# Root endpoint
get '/' do
  data = {
    response_status: "ok",
  }
  send_json(data)
rescue StandardError => e
  handle_error(e)
end

# POST endpoint for general data
post '/' do
  validate_params(params, [:data])
  prams_data = params[:data]
  data = {
    response_status: "ok",
    data: prams_data
  }
  send_json(data)
rescue StandardError => e
  handle_error(e)
end

# POST endpoint for next stage
post '/distance' do
  validate_params(params, [:team_id, :distance, :time_stamp])

  team_id = params[:team_id].to_s
  distance = params[:distance].to_f

  # find_or_initialize_byを利用してレコードがなければ作成、あれば取得
  game_status = GameStatusList.find_or_initialize_by(team_id: team_id)
  game_status.distance = distance
  game_status.save

  data = {
    response_status: "ok",
  }
  send_json(data)
rescue StandardError => e
  handle_error(e)
end

# POST endpoint for game clear
post '/game_clear' do
  validate_params(params, [:team_id, :time_stamp])

  team_id = params[:team_id].to_s

  # team_idを基準にしてレコードを検索し、新規作成・更新する
  game_status = GameStatusList.find_or_initialize_by(team_id: team_id)
  game_status.is_clear= true
  game_status.save

  data = {
    response_status: "ok",
  }
  send_json(data)
rescue StandardError => e
  handle_error(e)
end

get '/fetch_game_status' do
  begin
    game_status_lists = GameStatusList.all

    data = {
      response_status: "ok",
      game_statuses: game_status_lists.map do |status|
        {
          team_id: status.team_id,
          distance: status.distance,
          is_clear: status.is_clear,
          created_at: status.created_at,
          updated_at: status.updated_at
        }
      end
    }

    content_type :json
    data.to_json
  rescue StandardError => e
    handle_error(e)
  end
end

delete '/reset' do
  begin
    GameStatusList.delete_all
    data = {
      response_status: "ok",
      message: "GameStatusList has been reset."
    }

    binding.pry
    send_json(data)
  rescue StandardError => e
    handle_error(e)
  end
end

# Method to send JSON response
private
  def send_json(data)
    content_type :json
    data.to_json
  end

# Method to handle errors
private
  def handle_error(error)
    status 500
    error_data = {
      response_status: "error",
      error_message: error.message,
    }
    send_json(error_data)
  end

# Method to validate required params
def validate_params(params, required_keys)
  missing_keys = required_keys.select { |key| params[key].nil? || params[key].strip.empty? }
  unless missing_keys.empty?
    raise "Missing required parameters: #{missing_keys.join(', ')}"
  end

  # team_idのバリデーション
  if params[:team_id] && !params[:team_id].match?(/\A[A-Z]+\z/)
    raise "Invalid team_id: #{params[:team_id]}. It should only contain uppercase alphabetic characters."
  end
end
