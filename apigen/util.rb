##
# Creates a setter method for :attribute.
#
# Unlike attribute_writer, the setter method has no equal sign.
#  attribute_setter :name
# is equivalent to:
#  def name(value)
#    @name = value
#  end
def attribute_setter(attribute)
  define_method("#{attribute}".to_sym) do |value|
    instance_variable_set("@#{attribute}", value)
  end
end
