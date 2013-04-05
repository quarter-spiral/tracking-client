ENV['RACK_ENV'] ||= 'test'

Bundler.require

require 'minitest/autorun'

require 'tracking-client'
require 'tracking-client/test_helpers'