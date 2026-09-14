module ApplicationHelper
  # Renders a table header cell that links to sort the current index by
  # `column` (a key from the controller's SORTABLE_COLUMNS), toggling
  # direction when it's already the active sort column. Preserves any
  # other filter query params (severity, status, etc).
  def sortable_header(title, column)
    active = sort_column == column
    direction = active && sort_direction == "asc" ? "desc" : "asc"
    arrow = active ? (sort_direction == "asc" ? " ▲" : " ▼") : ""

    link_to url_for(request.query_parameters.merge(sort: column, direction: direction)), class: "hover:underline" do
      safe_join([ title, arrow ])
    end
  end
end
