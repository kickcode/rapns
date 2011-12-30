module Rapns
  class Notification
    include MongoMapper::Document    

    key :badge, Integer
    key :device_token, String, limit: 64
    key :sound, String, default: "1.aiff"
    key :alert, String
    key :attributes_for_device, String
    key :expiry, Integer, default: 1.day.to_i
    key :delivered, Boolean, default: false
    key :delivered_at, Time
    key :failed, Boolean, default: false
    key :failed_at, Time
    key :error_code, Integer
    key :error_description, String
    key :deliver_after, Time

    timestamps!    
    
    validates :device_token, :presence => true, :format => { :with => /^[a-z0-9]{64}$/ }
    validates :badge, :numericality => true, :allow_nil => true
    validates :expiry, :numericality => true, :presence => true
    scope :ready_for_delivery, lambda { where(:delivered => false, :failed => false).where(:$or => [{:deliver_after => nil}, {:deliver_after => {:$lt => Time.now}}]) }

    validates_with Rapns::BinaryNotificationValidator

    def device_token=(token)
      write_attribute(:device_token, token.delete(" <>")) if !token.nil?
    end

    def attributes_for_device=(attrs)
      raise ArgumentError, "attributes_for_device must be a Hash" if !attrs.is_a?(Hash)
      write_attribute(:attributes_for_device, ActiveSupport::JSON.encode(attrs))
    end

    def attributes_for_device
      ActiveSupport::JSON.decode(read_attribute(:attributes_for_device)) if read_attribute(:attributes_for_device)
    end

    def as_json
      json = ActiveSupport::OrderedHash.new
      json['aps'] = ActiveSupport::OrderedHash.new
      json['aps']['alert'] = alert unless alert.blank? || alert == "false"
      json['aps']['badge'] = badge unless badge.blank? || badge == "false"
      json['aps']['sound'] = sound unless sound.blank? || sound == "false"
      attributes_for_device.each { |k, v| json[k.to_s] = v.to_s } if attributes_for_device
      json
    end

    # This method conforms to the enhanced binary format.
    # http://developer.apple.com/library/ios/#documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CommunicatingWIthAPS/CommunicatingWIthAPS.html#//apple_ref/doc/uid/TP40008194-CH101-SW4
    def to_binary(options = {})
      id_for_pack = options[:for_validation] ? 0 : self.id.to_s.each_byte.to_a.join.to_i
      json = as_json.to_json
      [1, id_for_pack, expiry.to_i, 0, 32, device_token, 0, json.size, json].pack("cNNccH*cca*")
    end
  end
end
