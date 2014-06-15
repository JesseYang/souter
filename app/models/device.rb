# encoding: utf-8
class Device
  include Mongoid::Document
  include Mongoid::Timestamps

  # status
  DISCONNECTED = 1
  CONNECTED = 2

  field :name, type: String
  field :code, type: String
  field :status, type: Integer, default: DISCONNECTED
  field :current_ip, type: String

  has_many :loc_infos

  def self.recv_loc_info(ip, content)
    code, content = *content.split("#")
    d = Device.where(code: code).first
    return if d.nil?
    loc_info = LocInfo.create_new(content)
    d.loc_infos << loc_info
  end
end
