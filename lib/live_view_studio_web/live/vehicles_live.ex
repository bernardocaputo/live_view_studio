defmodule LiveViewStudioWeb.VehiclesLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudioWeb.CustomComponents
  alias LiveViewStudio.Vehicles

  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        vehicles: [],
        loading: false,
        matches: %{},
        query: ""
      )

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>🚙 Find a Vehicle 🚘</h1>
    <div id="vehicles">
      <form phx-submit="search" phx-change="suggest">
        <input
          type="text"
          name="query"
          value={@query}
          placeholder="Make or model"
          autofocus
          autocomplete="off"
          readonly={@loading}
          list="matches"
        />

        <button>
          <img src="/images/search.svg" />
        </button>
      </form>

      <datalist id="matches">
        <option :for={match <- @matches} value={match}>
          <%= match %>
        </option>
      </datalist>

      <CustomComponents.loading visible={@loading} />

      <div class="vehicles">
        <ul>
          <li :for={vehicle <- @vehicles}>
            <span class="make-model">
              <%= vehicle.make_model %>
            </span>
            <span class="color">
              <%= vehicle.color %>
            </span>
            <span class={"status #{vehicle.status}"}>
              <%= vehicle.status %>
            </span>
          </li>
        </ul>
      </div>
    </div>
    """
  end

  def handle_event("search", %{"query" => mm}, socket) do
    send(self(), {:run_search, mm})

    socket = assign(socket, loading: true, query: mm)

    {:noreply, socket}
  end

  def handle_event("suggest", %{"query" => prefix}, socket) do
    socket = assign(socket, matches: Vehicles.suggest(prefix))

    {:noreply, socket}
  end

  def handle_info({:run_search, mm}, socket) do
    socket = assign(socket, vehicles: Vehicles.search(mm), loading: false)

    {:noreply, socket}
  end
end
