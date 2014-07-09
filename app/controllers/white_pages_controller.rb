require 'whitepages'

class WhitePagesController < ApplicationController
  def phone_lookup
    unless params['phone'].blank?

    wp = Whitepages.new("6b5a968507f728b72bac005321001c28")
    data = wp.reverse_phone({ "phone"   => params['phone']})
    render :json => data.to_json, :status => 200 and return false
    end
  end

end
