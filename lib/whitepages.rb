require 'json'
require 'uri'
require 'httparty'

#This class holds the methods for consuming the Whitepages API
class Whitepages

  #Initialize the Whitepages class
  # * api_key - The API key obtained from the Whitpages Developer website
  def initialize(api_key)
    api_version = "2.0/"

    @api_key = api_key
    @base_uri = "http://proapi.whitepages.com/"
    @reverse_phone_uri = @base_uri + api_version + "phone.json?"

    #@uri = URI.parse(@base_uri)
    #@http = Net::HTTP.new(@uri.host, @uri.port)
  end

  #Retrieves contact information about a telephone number
  def reverse_phone(options)
    #resp, data = @http.get(build_uri(options, "reverse_phone"))
    #resp, data = HTTParty.get(URI.escape(build_uri(options, "reverse_phone")))
    # return JSON.parse(data)
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


  def data(response)
      unless response.blank?
        results_phones_array = []
        response["results"].each do|result_phone|
          results_phones_array << result_phone
        end

        dictionaryData = response['dictionary'];

        person_keys_array= []
        request_phone_details = []
        city = ""
        state_code = ""
        postal_code = ""
        standard_address_line1 = ""
        standard_address_line2 = ""
        first_name = ""
        last_name = ""
        reputation   = ""

        location_keys_array   = []
        results_phones_array.each do|phone_obj|
          phoneObj = dictionaryData[phone_obj]

          belongs_to_array = phoneObj['belongs_to']

          belongs_to_array.each do |belongs_to_obj|
            belongs_obj = belongs_to_obj["id"]
            person_keys_array <<  belongs_obj["key"]
          end


          reputation  = phoneObj['reputation'].blank? ? 0 : phoneObj['reputation']['spam_score']

          best_location_array = phoneObj['best_location']
          unless best_location_array.blank?
            best_location_id = best_location_array["id"]
            location_keys_array <<  best_location_id["key"]
          end
        end

        location_keys_hash = Hash.new()

        unless person_keys_array.blank?
          person_keys_array.each_with_index do|person_obj,person_index|
            personObj = dictionaryData[person_obj]

            unless personObj["name"].blank?
              person_name = personObj["name"]

              unless person_name.index(" ").blank?
                if person_name.index(" ") > 0
                  person_name_arr = person_name.to_s.split(" ")
                  if person_name_arr.length > 2
                    fname = ""
                    for i in 0..person_name_arr.length-2
                      fname = fname + person_name_arr[i] + " "
                    end
                    first_name = name
                    last_name = person_name_arr[person_name_arr.length-1]

                  else
                    first_name = person_name_arr[0]
                    last_name = person_name_arr[1]
                  end
                end

              else
                first_name = person_name
              end

            end

            unless personObj["names"].blank?
              personObjNames =  personObj["names"]
              unless personObjNames.blank?
                first_name = personObjNames[0]["first_name"].blank? ? "" : personObjNames[0]["first_name"]+" "
                last_name =  personObjNames[0]["last_name"].blank? ? "" : personObjNames[0]["last_name"]
              end
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


        unless location_keys_hash.blank?
          location_keys_hash.each {|key, value|
            locationObj = dictionaryData[value]
            city = locationObj["city"]
            postal_code = locationObj["postal_code"]
            state_code = locationObj["state_code"]
            standard_address_line1  = locationObj["standard_address_line1"]
            standard_address_line2 =  locationObj["standard_address_line2"]
          }
        end

        unless location_keys_array.blank?
          location_keys_hash[0] = location_keys_array[0]
          locationObj = dictionaryData[location_keys_array[0]]
          city  = locationObj["city"]
          postal_code = locationObj["postal_code"]
          state_code = locationObj["state_code"]
          standard_address_line1  = locationObj["standard_address_line1"]
          standard_address_line2 =  locationObj["standard_address_line2"]
        end

        request_phone_details <<  first_name.strip
        request_phone_details <<  last_name.strip
        request_phone_details <<  city
        request_phone_details <<  state_code
        request_phone_details <<  postal_code
        request_phone_details <<  standard_address_line1
        request_phone_details << standard_address_line2
        request_phone_details << reputation
      end
      return request_phone_details
      #render :json => request_phone_details.to_json, :status => 200 and return false
  end

end