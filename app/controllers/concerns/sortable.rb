# Generic click-to-sort support for index tables.
#
# Including controller must define a SORTABLE_COLUMNS hash mapping a
# public sort key (used in the `sort` query param, and in view links)
# to the actual SQL column/expression to order by, e.g.:
#
#   SORTABLE_COLUMNS = { "hostname" => "assets.hostname", "risk" => "assets.risk_score" }.freeze
#   DEFAULT_SORT_COLUMN = "risk"
#   DEFAULT_SORT_DIRECTION = "desc"
module Sortable
  extend ActiveSupport::Concern

  included do
    helper_method :sort_column, :sort_direction
  end

  private
    def sort_column
      columns = self.class::SORTABLE_COLUMNS
      columns.key?(params[:sort]) ? params[:sort] : self.class::DEFAULT_SORT_COLUMN
    end

    def sort_direction
      params[:direction] == "desc" ? "desc" : "asc"
    end

    def sort_order
      Arel.sql("#{self.class::SORTABLE_COLUMNS.fetch(sort_column)} #{sort_direction}")
    end
end
