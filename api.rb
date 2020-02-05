# Gems to use
require 'sinatra'
require 'mongoid'

# DB Setup
Mongoid.load!(File.join(File.dirname(__FILE__), 'config', 'mongoid.yml'))

# Models
# Each of the places to be added on the map
class Location
  include Mongoid::Document

  field :name, type: String
  has_one :position

  validates :name, presence: true
  validates :coordinates, presence: true

  index(name: 'text')
end

# Array of coordinates X and Y
class Position
  include Mongoid::Document
  field :latitude, type: String
  field :longitude, type: String

  belongs_to :location
end

# Endpoints
get '/' do
  'Welcome to Location Api.'
end