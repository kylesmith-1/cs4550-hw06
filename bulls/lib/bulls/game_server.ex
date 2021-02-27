defmodule Bulls.GameServer do
  use GenServer

  alias Bulls.BackupAgent
  alias Bulls.Game

  # public interface

  def reg(name) do
    {:via, Registry, {Bulls.GameReg, name}}
  end

  def start(name) do
    spec = %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [name]},
      restart: :permanent,
      type: :worker
    }
    Bulls.GameSup.start_child(spec) #should be fine
  end

  def start_link(name) do
    game = BackupAgent.get(name) || Game.new
    GenServer.start_link(
      __MODULE__, #module
      game, #server implementation
      name: reg(name) #initial argument
    )
  end

  def reset(name) do
    GenServer.call(reg(name), {:reset, name})
  end

  def guess(name, letter, username) do
    GenServer.call(reg(name), {:guess, name, letter, username})
  end

  def peek(name) do
    GenServer.call(reg(name), {:peek, name})
  end

  def login(name, username) do
    GenServer.call(reg(name), {:login, name, username})
  end

  def become_player(name, username) do
    GenServer.call(reg(name), {:becomePlayer, name, username})
  end

  def become_ready(name, username) do
    GenServer.call(reg(name), {:becomeReady, name, username})
  end

  # implementation

  def init(game) do
    #Process.send_after(self(), :pook, 10_000)
    {:ok, game}
  end

  def handle_call({:reset, name}, _from, game) do
    game = Game.new
    BackupAgent.put(name, game)
    {:reply, game, game}
  end

  def handle_call({:guess, name, letter, username}, _from, game) do
    game = Game.guess(game, letter, username)
    BackupAgent.put(name, game)
    {:reply, game, game}
  end

  def handle_call({:becomePlayer, name, username}, _from, game) do
    game = Game.attemptBecomePlayer(game, username)
    BackupAgent.put(name, game)
    {:reply, game, game}
  end

  def handle_call({:becomeReady, name, username}, _from, game) do
    game = Game.attemptMakeReady(game, username)
    BackupAgent.put(name, game)
    {:reply, game, game}
  end

  #adding for login
  def handle_call({:login, name, username}, _from, game) do
    game = Game.login(game, username)
    BackupAgent.put(name, game)
    {:reply, game, game}
  end

  def handle_call({:peek, _name}, _from, game) do
    {:reply, game, game}
  end

  def handle_info(:pook, game) do
    game = Game.guess(game, "q")
    BullsWeb.Endpoint.broadcast!(
      "game:1", # FIXME: Game name should be in state
      "view",
      Game.view(game, "", ""))
    {:noreply, game}
  end
end
