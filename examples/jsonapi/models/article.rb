# frozen_string_literal: true

JsonApiExample::API.model :article do
  type :object do
    type :enum do
      value 'articles'
    end
    id :string
    attributes :object do
      title :string
    end
    relationships :object do
      author :object do
        links :object do
          property 'self', :link
          related :link
        end
        data :entity_reference
      end
      comments :object do
        links :object do
          property 'self', :link
          related :link
        end
        data :array do
          type :entity_reference
        end
      end
    end
    links :object do
      property 'self', :link
    end
  end
end
