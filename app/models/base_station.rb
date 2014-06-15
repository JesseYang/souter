require 'array'
require 'math'
class BaseStation
  include Mongoid::Document
  include HTTParty

  # base_uri 'http://www.minigps.net'
  base_uri 'http://www.minigps.org'
  format :json

  field :uniq_id, :type => Integer
  # mcc, mnc, lac and cellid can identify at most only one BS
  # Mobile Country Code (mcc): 460 for China
  field :mcc, :type => Integer
  # Mobile Network Code (mcc): 0 for China Mobile; 1 for China Unicom, 2 for China Telecom
  field :mnc, :type => Integer
  # Location Area Code (lac)
  field :lac, :type => Integer
  # Cell Identity
  field :cellid, :type => Integer
  field :lat, :type => Float
  field :lng, :type => Float
  field :lat_offset, :type => Float
  field :lng_offset, :type => Float
  field :lat_api, :type => Float
  field :lng_api, :type => Float
  field :radius, :type => Integer
  field :description, :type => String


  index({ uniq_id: 1 }, { background: true })
  index({ mcc: 1, mnc: 1, lac: 1, cellid: 1 })

  def self.find_bs_by_info(bs_info)
    result = self.get("/l.do",
      {:query => {
        :needaddress => 0,
        :c => bs_info["mcc"],
        :n => bs_info["mnc"],
        :a => bs_info["lac"],
        :e => bs_info["cellid"],
        :mt => 0},
        :headers => { 'Content-Type' => 'application/json;charset=UTF-8' } })
    if result.code != 200
      Rails.logger.info "AAAAAAAAAAAAAA"
      Rails.logger.info result.code
      Rails.logger.info "AAAAAAAAAAAAAA"
    end
    puts result.parsed_response
    result = result.parsed_response
    bs = BaseStation.where(mcc: bs_info["mcc"], mnc: bs_info["mnc"], lac: bs_info["lac"], cellid: bs_info["cellid"]).first
    return bs if result["cause"] != "OK"
    bs = BaseStation.create(mcc: bs_info["mcc"], mnc: bs_info["mnc"], lac: bs_info["lac"], cellid: bs_info["cellid"]) if bs.nil?
    bs.lat = result["lat"].to_f
    bs.lng = result["lon"].to_f
    offset = Offset.correct(bs.lat_api, bs.lng_api)
    bs.lat_offset = offset[0]
    bs.lng_offset = offset[1]
    bs.save
    return bs
  end
end
