module Rapns
  class Notification
    include Mongoid::Document
    include Mongoid::Timestamps

    field :badge, type: Integer
    field :device_token, type: String, limit: 64
    field :sound, type: String, default: "1.aiff"
    field :alert, type: String
    field :attributes_for_device, type: String
    field :expiry, type: Integer, default: 1.day.to_i
    field :delivered, type: Boolean, default: false
    field :delivered_at, type: Time
    field :failed, type: Boolean, default: false
    field :failed_at, type: Time
    field :error_code, type: Integer
    field :error_description, type: String
    field :deliver_after, type: Time

    validates :device_token, :presence => true, :format => { :with => /^[a-z0-9]{64}$/ }
    validates :badge, :numericality => true, :allow_nil => true
    validates :expiry, :numericality => true, :presence => true
    scope :ready_for_delivery, lambda { where(:delivered => false, :failed => false).any_of({:deliver_after => nil}, {:deliver_after.lt => Time.now}) }

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
