defmodule LiveViewStudioWeb.PizzaOrdersLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudio.PizzaOrders
  alias LiveViewStudioWeb.CustomComponents
  import Number.Currency

  def mount(_params, _session, socket) do
    {:ok, socket, temporary_assigns: [pizza_orders: []]}
  end

  def handle_params(params, _uri, socket) do
    sort_by = valid_sort_by(params)
    sort_order = valid_sort_order(params)

    options = %{
      sort_by: sort_by,
      sort_order: sort_order,
      page: param_to_integer(params["page"], 1),
      per_page: param_to_integer(params["per_page"], 5)
    }

    socket =
      assign(socket,
        pizza_orders: PizzaOrders.list_pizza_orders(options),
        options: options
      )

    {:noreply, socket}
  end

  def handle_event("select-per-page", %{"per_page" => per_page}, socket) do
    options = %{socket.assigns.options | per_page: param_to_integer(per_page, 5)}

    socket = push_patch(socket, to: ~p"/pizza-orders?#{options}")

    {:noreply, socket}
  end

  def sort_link(assigns) do
    ~H"""
    <.link patch={
      ~p"/pizza-orders?sort_by=#{@sort_by}&sort_order=#{CustomComponents.toggle_sort_order(@options.sort_order)}"
    }>
      <%= render_slot(@inner_block) %>
      <%= CustomComponents.sort_indicator(@sort_by, @options) %>
    </.link>
    """
  end

  defp valid_sort_by(%{"sort_by" => sort_by})
       when sort_by in ~w(id size style topping_1 topping_2 price),
       do: String.to_existing_atom(sort_by)

  defp valid_sort_by(_), do: :id

  defp valid_sort_order(%{"sort_order" => sort_order}) when sort_order in ~w(asc desc),
    do: String.to_existing_atom(sort_order)

  defp valid_sort_order(_), do: :asc

  defp param_to_integer(nil, default), do: default

  defp param_to_integer(params, default) do
    case Integer.parse(params) do
      {number, _} -> number
      :error -> default
    end
  end
end
