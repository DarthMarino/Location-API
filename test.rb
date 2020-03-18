require 'ostruct'
require 'json'

json_string = '{"name":"Ferreteria #1","position": [{"latitude":"18.45215","longitude":"-69.97621"}]}'
data = JSON.parse(json_string, object_class: OpenStruct)
puts data
puts data.name
puts data.position[:latitude]