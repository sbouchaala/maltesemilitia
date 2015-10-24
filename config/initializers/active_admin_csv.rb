module ActiveAdmin
  class ResourceController < BaseController

    # This module deals with the retrieval of collections for resources
    # within the resource controller.
    module Collection
      module Pagination

        def max_csv_records
          200_000
        end

        def max_per_page
          200_000
        end
      end
    end
  end
end