# frozen_string_literal: true

JsonApiExample::API.model :person do
  description 'A person.'
  type :object do
    type :enum do
      value 'people'
    end
    id :string
    attributes :object do
      property 'first-name', :string
      property 'last-name', :string
      twitter :string
    end
    links :object do
      property 'self', :link
    end
  end
end
