require 'csv'
class Offset
  include Mongoid::Document
  store_in collection: "offsets", database: "tracker_production", session: "offset"
  field :lng, :type => Float
  field :lat, :type => Float
  field :offset_lng, :type => Float
  field :offset_lat, :type => Float

  index({ lng: 1, lat: 1 }, { background: true })

  def self.import_data
    total_number = 0
    1.upto(10).each do |file_index|
      path = "data/offset#{file_index}.csv"
      CSV.foreach(path) do |row|
        next if row[0] == "lng"
        self.create(:lng => row[0].to_f,
          :lat => row[1].to_f,
          :offset_lng => row[2].to_f,
          :offset_lat => row[3].to_f)
        total_number += 1
        puts total_number if total_number % 1000 == 0
      end
    end
  end

  def self.correct(latitude, longitude)
    record = self.where(lng: longitude.round(2), lat: latitude.round(2)).first
    return [latitude, longitude] if record.blank?
    return [latitude + record.offset_lat, longitude + record.offset_lng]
  end
end
