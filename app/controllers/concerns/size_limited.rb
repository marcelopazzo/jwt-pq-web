module SizeLimited
  extend ActiveSupport::Concern

  class PayloadTooLarge < StandardError
    attr_reader :field

    def initialize(field)
      @field = field
      super("#{field} too large")
    end
  end

  def check_size!(value, max_bytes, field_name)
    raise PayloadTooLarge.new(field_name) if value.bytesize > max_bytes

    value
  end
end
