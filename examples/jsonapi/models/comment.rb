# frozen_string_literal: true

JsonApiExample::API.model :comment do
  description 'A comment.'
  type :object do
    type :enum do
      value 'comments'
    end
    id :string
    attributes :object do
      body :string
    end
    relationships :object do
      author :object do
        data :entity_reference
      end
    end
    links :object do
      property 'self', :link
    end
  end
end
