# Gems to use
require 'sinatra'
require 'sinatra/namespace'
require 'mongoid'
require 'mongoid/geospatial'
require 'ostruct'



# DB Setup
Mongoid.load!(File.join(File.dirname(__FILE__), '.config', 'mongoid.yml'))

# Models
# Each of the places to be added on the map
class Location
  include Mongoid::Document
  include Mongoid::Geospatial

  field :name, type: String
  field :location, type: Point

  spatial_index :location

  validates :name, presence: true
  validates :location, presence: true

  index({ name: 'text' })

  scope :name, ->(name) { where(name: /^#{name}/) }
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
      location:@location.location
    }
    data[:errors] = @location.errors if@location.errors.any?
    data
  end

end

# Endpoints
get '/' do
  redirect "/api/v1/locations"
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
        json_string = request.body.read
        JSON.parse(json_string, object_class: OpenStruct)
      rescue
        halt 400, { message: 'Invalid JSON' }.to_json
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

      [:name, :location].each do |filter|
        locations = locations.send(filter, params[filter]) if params[filter]
      end

      locations.map { |location| LocationSerializer.new(location) }.to_json
  end

  get '/locations/:id' do
    halt_if_not_found!
    serialize(location)
  end

  post '/locations' do
    datajson = json_params
    Location.create(
      name: datajson.name.to_s,
      location: {latitude: datajson.location[:latitude], longitude: datajson.location[:longitude]}
    )
  end

  patch '/locations/:id' do
    halt_if_not_found!
    halt 422, serialize(location) unless location.update_attributes(json_params)
    serialize(location)
  end

  delete '/locations/:id' do
    location.destroy if location
    status 204
  end
end
