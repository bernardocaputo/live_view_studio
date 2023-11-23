defmodule LiveViewStudioWeb.ServersLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudio.Servers
  alias LiveViewStudio.Servers.Server

  # why not {:ok, socket, temporary_assigns: [servers: []]} ?

  #   When a server is selected, the active CSS class needs to be added to that server's link in the
  # sidebar. So when a new value is assigned to selected_server, this hunk of HEEx is re-evaluated:

  # <.link
  #   :for={server <- @servers}
  #   patch={~p"/servers?#{[id: server]}"}
  #   class={if server == @selected_server, do: "selected"}
  # >
  # And when the new list of servers is rendered, the value of @servers will be an empty list. Therefore,
  # the :for comprehension won't render anything.

  def mount(_params, _session, socket) do
    servers = Servers.list_servers()

    socket =
      assign(socket,
        servers: servers,
        coffees: 0
      )

    {:ok, socket}
  end

  # ~p verifica se a rota está setada no router.ex. Se não tiver, vai gerar um erro na compilação
  # link built-in function component que faz a mesma coisa que o <a> mas traz a funcionalidade do
  # patch e navigate. Se utilizarmos o href convencional do <a> ele vai redirecionar pro nova url
  # e vai lidar como se fosse uma nova requisição. Então vai chamar o mount de novo e um novo
  # processo de Liveview será criado (novo pid). Se utilizarmos o patch, ele mostra que queremos
  # redirecionar pro novo url no mesmo liveview (ServersLive) mas utilizando o websocket já conectado.
  # Assim, o state não será perdido. o Navigate é a mesma coisa que o patch, mas para um novo componente/
  # liveview (LightLive por exemplo)
  def render(assigns) do
    ~H"""
    <h1>Servers</h1>
    <div id="servers">
      <div class="sidebar">
        <div class="nav">
          <.link patch={~p"/servers/new"} class="add">
            + Add New Server
          </.link>
          <.link
            :for={server <- @servers}
            patch={~p"/servers/#{server.id}"}
            class={if server == @selected_server, do: "selected"}
          >
            <span class={server.status}></span>
            <%= server.name %>
          </.link>
        </div>
        <div class="coffees">
          <button phx-click="drink">
            <img src="/images/coffee.svg" />
            <%= @coffees %>
          </button>
        </div>
      </div>

      <div class="main">
        <div class="wrapper">
          <%= if @live_action == :new do %>
            <.form for={@form} phx-submit="save">
              <div class="field">
                <.input
                  field={@form[:name]}
                  placeholder="name"
                  autocomplete="off"
                />
              </div>
              <%!-- <.label for={:name}>Name</.label> --%>
              <%!-- <.label for={:framework}>Framework</.label> --%>
              <div class="field">
                <.input
                  field={@form[:framework]}
                  placeholder="framework"
                  autocomplete="off"
                />
              </div>
              <%!-- <.label for={:size}>Size (MB)</.label> --%>
              <div class="field">
                <.input
                  field={@form[:size]}
                  placeholder="size"
                  type="number"
                  autocomplete="off"
                />
              </div>

              <.button phx-disable-with="Saving...">
                Save
              </.button>
              <.link class="cancel" patch={~p"/servers"}>
                Cancel
              </.link>
            </.form>
          <% else %>
            <.server server={@selected_server} />
          <% end %>
          <div class="links">
            <.link navigate={~p"/light"}>
              Adjust Lights
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Since handle_params is always invoked after mount to handle URL query parameters, you might be
  #  wondering whether it's best to assign a LiveView's initial state in mount or handle_params.

  # As a general rule of thumb, if you have state that can change based on URL parameters, then you should
  # assign that state in handle_params. Otherwise, any other state can be assigned in mount which is
  # invoked once per LiveView lifecycle.

  def handle_event("drink", _, socket) do
    {:noreply, update(socket, :coffees, &(&1 + 1))}
  end

  def handle_event("save", %{"server" => server}, socket) do
    case Servers.create_server(server) do
      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}

      {:ok, server} ->
        form = to_form(Servers.change_server(%Server{}))

        socket =
          socket
          |> push_patch(to: ~p"/servers/#{server}")
          |> update(:servers, fn servers -> [server | servers] end)
          |> assign(:form, form)

        {:noreply, socket}
    end
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    selected_server = Servers.get_server!(id)
    {:noreply, assign(socket, selected_server: selected_server)}
  end

  def handle_params(_, _uri, socket) do
    socket =
      if socket.assigns.live_action == :new do
        changeset = Servers.change_server(%Server{})

        assign(socket,
          selected_server: nil,
          form: to_form(changeset)
        )
      else
        assign(socket,
          selected_server: hd(socket.assigns.servers)
        )
      end

    {:noreply, socket}
  end

  attr :server, Servers.Server, required: true

  defp server(assigns) do
    ~H"""
    <div class="server">
      <div class="header">
        <h2><%= @server.name %></h2>
        <span class={@server.status}>
          <%= @server.status %>
        </span>
      </div>
      <div class="body">
        <div class="row">
          <span>
            <%= @server.deploy_count %> deploys
          </span>
          <span>
            <%= @server.size %> MB
          </span>
          <span>
            <%= @server.framework %>
          </span>
        </div>
        <h3>Last Commit Message:</h3>
        <blockquote>
          <%= @server.last_commit_message %>
        </blockquote>
      </div>
    </div>
    """
  end
end
