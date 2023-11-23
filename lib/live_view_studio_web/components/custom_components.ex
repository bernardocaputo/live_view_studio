defmodule LiveViewStudioWeb.CustomComponents do
  use LiveViewStudioWeb, :html

  attr :visible, :boolean, default: false

  def loading(assigns) do
    ~H"""
    <div :if={@visible} class="flex justify-center my-10 relative">
      <div class="w-12 h-12 rounded-full absolute border-8 border-gray-300">
      </div>
      <div class="w-12 h-12 rounded-full absolute border-8 border-indigo-400 border-t-transparent animate-spin">
      </div>
    </div>
    """
  end

  def toggle_sort_order(:asc), do: :desc
  def toggle_sort_order(:desc), do: :asc

  def sort_indicator(column, %{sort_by: sort_by, sort_order: sort_order})
      when column == sort_by do
    case sort_order do
      :asc -> "👆"
      :desc -> "👇"
    end
  end

  def sort_indicator(_, _), do: ""
end
