ENV['RACK_ENV'] ||= 'test'

Bundler.require

require 'minitest/autorun'

require 'tracking-client'
require 'tracking-client/test_helpers'

require_relative './spec_utility_methods'
include Tracking::Client::SpecUtilityMethods