# encoding: utf-8
class LocInfo
  include Mongoid::Document
  include Mongoid::Timestamps

  field :content, type: String
  field :ip, type: String
  # each element of bs_ss corresponds to one bs, and is a hash, the keys of which are:
  #   mcc:
  #   mnc:
  #   lac:
  #   cellid:
  #   ss:
  # the former four can identify at most one bs
  field :bs_ss, :type => Array
  field :lat, :type => Float
  field :lng, :type => Float
  field :lat_offset, :type => Float
  field :lng_offset, :type => Float

  belongs_to :device

  # "1a2b3c#AT+ENBR\n\r\n+ENBR: 460, 01, 10CD, 62FE, 44, 656, 19\r\n\r\n+ENBR: 460, 01, 10CD, D735, 38, 111, 25\r\n\r\n+ENBR: 460, 01, 10CD, DE95, 32, 115, 12\r\n\r\n+ENBR: 460, 01, 10CD, 9FF4, 29, 639, 11\r\n\r\n+ENBR: 460, 01, 10CD, C67D, 45, 649, 11\r\n\r\n+ENBR: 460, 01, 10CD, , 32, 115, 12\r\n\r\n+ENBR: 460, 01, 10CD, , 29, 639, 11\r\n\r\nOK\r\n"
  def self.create_new(ip, content)
    bs_ss = []
    content.scan(/ENBR: (.+)\r/).each do |bs|
      elements = bs[0].split(',').map { |e| e.strip }
      next if elements.select { |e| e.blank? } .present?
      bs_ss << {mcc: bs[0].to_i,
        mnc: bs[1].to_i,
        lac: bs[2].to_i(16),
        cellid: bs[3].to_i(16),
        ss: bs[-1].to_f}
    end
    loc_info = self.create(ip: ip, content: content, bs_ss: bs_ss)
    loc_info.cal_bs_based_loc
  end

  def cal_bs_based_loc
    return if bs_ss.blank?
    bs_ary = []
    bs_ss.each do |bs_info|
      bs = BaseStation.find_bs_by_info(bs_info)
      next if bs.nil?
      bs_ary << {
        lat: bs.lat_std,
        lng: bs.lng_std,
        lat_offset: bs.lat_offset,
        lng_offset: bs.lng_offset,
        ss: bs_info["ss"].to_f}
    end
    return if bs_ary.blank?
    lat_offset_sum = lng_offset_sum = lat_sum = lng_sum = ss_sum = 0 
    bs_ary.each do |e|
      lat_offset_sum += e[:lat_offset] * e[:ss]
      lng_offset_sum += e[:lng_offset] * e[:ss]
      lat_sum += e[:lat] * e[:ss]
      lng_sum += e[:lng] * e[:ss]
      ss_sum += e[:ss]
    end
    self.lat_offset = (lat_offset_sum / ss_sum).round(6)
    self.lng_offset = (lng_offset_sum / ss_sum).round(6)
    self.lat = (lat_sum / ss_sum).round(6)
    self.lng = (lng_sum / ss_sum).round(6)
    self.save
  end
end
