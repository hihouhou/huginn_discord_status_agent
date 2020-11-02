require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::DiscordStatusAgent do
  before(:each) do
    @valid_options = Agents::DiscordStatusAgent.new.default_options
    @checker = Agents::DiscordStatusAgent.new(:name => "DiscordStatusAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
