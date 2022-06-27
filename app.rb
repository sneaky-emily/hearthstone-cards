require 'sinatra'
require './lib/hearthstone'
require './lib/cache_helper'

#################
#    Set Up     #
# Configuration #
#################

configure do
  # This does runtime initialization of anything that needs to be run at application boot (in this case, the cache),
  # however otherwise all calls static methods as there is no real state being utilized (outside of the cache itself)
  CacheHelper.new
end

#################
#  Application  #
#    Run Time   #
#################

get '/' do
  @cards = Hearthstone.detailed_cards
  erb :index
end
