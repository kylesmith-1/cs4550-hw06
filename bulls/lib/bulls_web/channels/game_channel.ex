defmodule BullsWeb.GameChannel do
  use BullsWeb, :channel

  alias Bulls.Game
  alias Bulls.GameServer

  @impl true
  def join("game:" <> name, payload, socket) do
    if authorized?(payload) do
      GameServer.start(name)
      socket = socket
      |> assign(:name, name)
      |> assign(:user, "")
      game = GameServer.peek(name)
      view = Game.view(game, "", "")
      {:ok, view, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in("login", %{"name" => user, "gameName" => gameName}, socket) do
    socket = assign(socket, :name, gameName)
    socket = assign(socket, :user, user)
    view = socket.assigns[:name]
    |> GameServer.login(user)
    |> Game.view(user, gameName)
    {:reply, {:ok, view}, socket}
  end

  @impl true
  def handle_in("guess", %{"number" => ll}, socket) do
    user = socket.assigns[:user]
    view = socket.assigns[:name]
    |> GameServer.guess(ll, user)
    |> Game.view(user, socket.assigns[:name])
    broadcast(socket, "view", view)
    {:reply, {:ok, view}, socket}
  end

  @impl true
  def handle_in("become_player", _, socket) do
    user = socket.assigns[:user]
    view = socket.assigns[:name]
    |> GameServer.become_player(user)
    |> Game.view(user, socket.assigns[:name])
    broadcast(socket, "view", view)
    {:reply, {:ok, view}, socket}
  end

  @impl true
  def handle_in("become_ready", _, socket) do
    user = socket.assigns[:user]
    view = socket.assigns[:name]
    |> GameServer.become_ready(user)
    |> Game.view(user, socket.assigns[:name])
    broadcast(socket, "view", view)
    {:reply, {:ok, view}, socket}
  end

  @impl true
  def handle_in("reset", _, socket) do
    user = socket.assigns[:user]
    view = socket.assigns[:name] # game name
    |> GameServer.reset()
    |> Game.view(user, socket.assigns[:name])
    broadcast(socket, "view", view)
    {:reply, {:ok, view}, socket}
  end

  intercept ["view"]

  @impl true
  def handle_out("view", msg, socket) do
    user = socket.assigns[:user]
    msg = %{msg | name: user}
    push(socket, "view", msg)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
