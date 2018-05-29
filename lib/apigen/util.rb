##
# Creates a setter method for :attribute.
#
# Unlike attribute_writer, the setter method has no equal sign.
#  attribute_setter :name
# is equivalent to:
#  def name value
#    @name = value
#  end
def attribute_setter attribute
  define_method "#{attribute}".to_sym do |value|
    instance_variable_set "@#{attribute}", value
  end
end

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
def attribute_setter_getter attribute
  define_method "#{attribute}".to_sym do |value = nil|
    if value.nil?
      instance_variable_get "@#{attribute}"
    else
      instance_variable_set "@#{attribute}", value
    end
  end
end
