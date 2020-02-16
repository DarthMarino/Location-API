# Gems to use
require 'sinatra'
require 'sinatra/namespace'
require 'mongoid'

# DB Setup
Mongoid.load!(File.join(File.dirname(__FILE__), 'config', 'mongoid.yml'))

# Models
# Each of the places to be added on the map
class Location
  include Mongoid::Document

  field :name, type: String
  field :position, type: Array

  validates :name, presence: true
  validates :position, presence: true

  index({name: 'text'})

  scope :name, -> (name) { where(name: /^#{name}/) }
end

# Serializer
class LocationSerializer
  def initialize(location)
    @location = location
  end

  def as_json(*)
    data = {
      id:@location.id.to_s,
      name:@location.name,
      position:@location.position
    }
    data[:errors] = @location.errors if@location.errors.any?
    data
  end
end

# Endpoints
get '/' do
  'Welcome to Locations List!'
end

namespace '/api/v1' do
  before do
    content_type 'application/json'
  end

  helpers do
    def base_url
      @base_url ||= "#{request.env['rack.url_scheme']}://{request.env['HTTP_HOST']}"
    end

    def json_params
      begin
        JSON.parse(request.body.read)
      rescue
        halt 400, { message: 'Invalid JSON' }.to_json
      end
    end

    def location
      @location ||= Location.where(id: params[:id]).first
    end

    def halt_if_not_found!
      halt(404, {message:'Location Not Found'}.to_json) unless location
    end

    def serialize(location)
      LocationSerializer.new(location).to_json
    end
  end

  get '/locations' do
      locations = Location.all

      [:name, :position].each do |filter|
        locations = locations.send(filter, params[filter]) if params[filter]
      end

      locations.map { |location| LocationSerializer.new(location) }.to_json
  end

  get '/locations/:id' do |id|
    halt_if_not_found!
    serialize(location)
  end

  post '/locations' do
    location = Location.new(json_params)
    halt 422, serialize(location) unless location.save

    response.headers['Location'] = "#{base_url}/api/v1/locations/#{location.id}"
    status 201
  end

  patch '/locations/:id' do |id|
    halt_if_not_found!
    halt 422, serialize(location) unless location.update_attributes(json_params)
    serialize(location)
  end

  delete '/locations/:id' do |id|
    location.destroy if location
    status 204
  end
end
