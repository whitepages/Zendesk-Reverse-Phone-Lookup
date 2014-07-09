require 'json'
require 'uri'
require 'httparty'

#This class holds the methods for consuming the Whitepages API
class Whitepages

  #Initialize the Whitepages class
  def initialize(api_key)
    api_version = "2.0/"

    @api_key = api_key
    @base_uri = "http://proapi.whitepages.com/"
    @reverse_phone_uri = @base_uri + api_version + "phone.json?"
  end

  #Retrieves contact information about a telephone number
  def reverse_phone(options)
    response = HTTParty.get(URI.escape(build_uri(options, "reverse_phone")))
    response = JSON.parse(response.to_json)
    return data(response)
  end

  private

  #Build the appropriate URL
  def build_uri(options, type)
    case type
      when "reverse_phone"
        built_uri = @reverse_phone_uri
    end

    options.each do |key,value|
      if value != nil
        built_uri = built_uri + key + "=" + value.gsub(' ', '%20') + "&"
      end
    end

    built_uri = built_uri + "api_key=" + @api_key
    return built_uri
  end


  def best_location(best_location_array)
    best_location = []
    unless best_location_array.blank?
      best_location_id = best_location_array["id"]
      best_location =  best_location_id["key"]
    end
    return best_location
  end

  def get_location(location_keys_hash,location_keys_array,dictionaryData)
    location_array = []
    if !location_keys_hash.blank?
      location_keys_hash.each {|key, value| location_array << dictionaryData[value]["city"] << dictionaryData[value]["postal_code"] << dictionaryData[value]["state_code"] << dictionaryData[value]["standard_address_line1"] << dictionaryData[value]["standard_address_line2"] }
    elsif !location_keys_array.blank?
      location_array << dictionaryData[location_keys_array[0]]["city"] << dictionaryData[location_keys_array[0]]["postal_code"] << dictionaryData[location_keys_array[0]]["state_code"] << dictionaryData[location_keys_array[0]]["standard_address_line1"] << dictionaryData[location_keys_array[0]]["standard_address_line2"]
    end
    return location_array
  end


  def name(personObjName)
    name_array = []
    unless personObjName.blank?
      unless personObjName.index(" ").blank?
        person_name_arr = personObjName.to_s.split(" ")
        name_array <<  person_name_arr[0] << person_name_arr[1]
      else
        name_array <<  person_name  << ""
      end
    end
    return name_array
  end


  def names(personObjNames)
    names_array = []
    unless personObjNames.blank?
      names_array <<  personObjNames[0]["first_name"].blank? ? "" : personObjNames[0]["first_name"]+" "   <<  personObjNames[0]["last_name"].blank? ? "" : personObjNames[0]["last_name"]
    end
    return names_array
  end

  def data(response)
    unless response.blank?
      results_phones_array = []
      response["results"].each do|result_phone|
        results_phones_array << result_phone
      end

      dictionaryData = response['dictionary'];
      person_keys_array= []
      person = Hash.new
      location_keys_array   = []
      results_phones_array.each do|phone_obj|
        phoneObj = dictionaryData[phone_obj]

        belongs_to_array = phoneObj['belongs_to']
        belongs_to_array.each do |belongs_to_obj|
          belongs_obj = belongs_to_obj["id"]
          person_keys_array <<  belongs_obj["key"]
        end
        person["reputation"]  = phoneObj['reputation'].blank? ? 0 : phoneObj['reputation']['spam_score']
        location_keys_array << best_location(phoneObj['best_location'])
      end

      location_keys_hash = Hash.new()

      unless person_keys_array.blank?
        person_keys_array.each_with_index do|person_obj,person_index|
          personObj = dictionaryData[person_obj]

          name_arr =  name(personObj["name"])
          unless name_arr.blank?
            person["first_name"] = name_arr[0]
            person["last_name"] = name_arr[1]
          end

          names_arr = names(personObj["names"])
          unless names_arr.blank?
            person["first_name"] =names_arr[0]
            person["last_name"] =names_arr[1]
          end

          unless personObj["locations"].blank?
            location_keys_array  = []
            personObj["locations"].each do|locations_obj|
              location_keys_hash[person_index] = locations_obj['id']['key']
            end
          end

          unless personObj["best_location"].blank?
            best_location_id = personObj["best_location"]["id"]
            unless best_location_id.blank?
              location_keys_array = []
              location_keys_hash[person_index] = best_location_id['key']
            end
          end
        end
      end

      location_var = get_location(location_keys_hash,location_keys_array,dictionaryData)
      unless location_var.blank?
        person["city"] =location_var[0]
        person["state_code"] =location_var[1]
        person["postal_code"] =location_var[2]
        person["standard_address_line1"] =location_var[3]
        person["standard_address_line2"] =location_var[4]
      end
    end
    return person
    #render :json => request_phone_details.to_json, :status => 200 and return false
  end

end