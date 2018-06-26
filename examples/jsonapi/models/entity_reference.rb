# frozen_string_literal: true

JsonApiExample::API.model :entity_reference do
  description 'A reference to an entity.'
  type :object do
    type :enum do
      value 'articles'
      value 'comments'
      value 'people'
    end
    id :string
  end
end
