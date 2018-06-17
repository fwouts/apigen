# frozen_string_literal: true

##
# Creates a setter/getter method for :attribute.
#
#  attribute_setter_getter :name
# is equivalent to:
#  def name value = nil
#    if value.nil?
#      @name
#    else
#      @name = value
#    end
#  end
def attribute_setter_getter(attribute)
  define_method attribute.to_s.to_sym do |value = nil|
    if value.nil?
      instance_variable_get "@#{attribute}"
    else
      instance_variable_set "@#{attribute}", value
    end
  end
end
