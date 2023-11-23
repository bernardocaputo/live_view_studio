defmodule LiveViewStudioWeb.DonationsLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudio.Donations
  import LiveViewStudioWeb.CustomComponents

  def mount(_params, _session, socket) do
    {:ok, socket, temporary_assigns: [donations: []]}
  end

  def handle_params(params, _uri, socket) do
    options = %{
      sort_by: valid_sort_by(params),
      sort_order: valid_sort_order(params),
      page: param_to_integer(params["page"], 1),
      per_page: param_to_integer(params["per_page"], 5)
    }

    donation_count = Donations.count_donations()
    donations = Donations.list_donations(options)

    socket =
      assign(socket,
        options: options,
        donations: donations,
        donation_count: donation_count
      )

    {:noreply, socket}
  end

  # até agora nós vínhamos atualizando a URL com o .link patch={} (utilizando a mesma conexão do websocket).
  # Porém, agora nós queremos atualizar a URL de dentro da aplicação. pra isso utilizamos o push_patch()
  # conforme abaixo. Ele
  def handle_event("select-per-page", %{"per_page" => per_page}, socket) do
    params = %{socket.assigns.options | per_page: per_page}

    socket = push_patch(socket, to: ~p"/donations?#{params}")

    {:noreply, socket}
  end

  attr :sort_by, :atom, required: true
  attr :options, :map, required: true
  slot :inner_block, required: true

  def sort_link(assigns) do
    params = %{
      assigns.options
      | sort_by: assigns.sort_by,
        sort_order: toggle_sort_order(assigns.options.sort_order)
    }

    assigns = assign(assigns, params: params)

    ~H"""
    <.link patch={~p"/donations?#{@params}"}>
      <%= render_slot(@inner_block) %>
      <%= sort_indicator(@sort_by, @options) %>
    </.link>
    """
  end

  defp valid_sort_by(%{"sort_by" => sort_by})
       when sort_by in ~w(item quantity days_until_expires) do
    String.to_existing_atom(sort_by)
  end

  defp valid_sort_by(_params), do: :id

  defp valid_sort_order(%{"sort_order" => sort_by})
       when sort_by in ~w(asc desc) do
    String.to_existing_atom(sort_by)
  end

  defp valid_sort_order(_params), do: :asc

  defp param_to_integer(nil, default), do: default

  defp param_to_integer(params, default) do
    case Integer.parse(params) do
      {number, _} -> number
      :error -> default
    end
  end

  defp more_pages?(options, donation_count) do
    options.page * options.per_page < donation_count
  end

  defp pages(options, donation_count) do
    page_count = ceil(donation_count / options.per_page)

    for page_number <- (options.page - 2)..(options.page + 2),
        page_number > 0 do
      if page_number <= page_count do
        current_page? = page_number == options.page
        {page_number, current_page?}
      end
    end
  end
end
