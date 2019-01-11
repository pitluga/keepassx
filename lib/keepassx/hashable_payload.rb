# frozen_string_literal: true

class HashablePayload < Hash
  include Hashie::Extensions::MergeInitializer
  include Hashie::Extensions::IndifferentAccess
end
