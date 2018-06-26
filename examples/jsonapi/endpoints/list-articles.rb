# frozen_string_literal: true

JsonApiExample::API.endpoint :list_articles do
  method :get
  path '/articles'
  output :success do
    status 200
    type :object do
      links :object do
        property 'self', :link
        property 'next', :link
        last :link
      end

      data :array do
        type :article
      end

      included :array do
        type :oneof do
          discriminator :type
          map(
            person: 'people',
            comment: 'comments'
          )
        end
      end
    end
  end
end
