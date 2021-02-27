# defmodule Bulls.Game do
#  @moduledoc """
#   Does computations for a game of Bulls and Cows. Built base from the following
#   lecture code: https://github.com/NatTuck/scratch-2021-01/blob/master/notes-4550/07-phoenix/notes.md
#   """

#   @type guess_display :: {
#     # sets type guess to type string
#     guess :: String.t(),
#     a :: non_neg_integer,
#     b :: non_neg_integer
#   }
# @type(state :: guesses :: [String.t()], {secret :: String.t()})


# def new do
# %{
# # MapSet is from lecture, can contain unique elements of any kind, no particular order
# guesses: MapSet.new(),
# secret: makeSecret(),
# error: ""
# }
# end


# #need to rethink makeSecret since we no longer have while loops, loose types, etc...
# def makeSecret do
# firstNum = Enum.take_random(1..9, 1)
# remainingNum = Enum.take_random(0..9, 3)
# secret = Enum.concat(firstNum, remainingNum) |> Enum.join()
# secret
# end

# def checkUnique(guess) do
# guessAsSet = MapSet.new(guess)
# MapSet.size(guessAsSet) > 3
# end


# def guess(st, num) do
# num_digits = String.graphemes(num) #graphemes was discovered from lecture, very useful!
# cond do
# !checkUnique(num_digits) ->
# # Enum.uniq(num_digits) != num_digits ->
#   %{st | error: "no duplicates allowed"}
# # https://hexdocs.pm/elixir/Regex.html and https://www3.ntu.edu.sg/home/ehchua/programming/howto/Regexe.html
# Regex.match?(~r/^[1-9]/, num) ->
#   %{st | guesses: MapSet.put(st.guesses, num), error: ""}
# end
# end

# def outOfGuesses?(st) do
# MapSet.size(st.guesses) >= 8
# end

# def isCorrectGuess?(st) do
# Enum.member?(st.guesses, st.secret)
# end


# #needed help with guesses and used https://dockyard.com/blog/2016/08/05/understand-capture-operator-in-elixir
# # to reference capture operator
# def view(st) do
# success = isCorrectGuess?(st) #if we correctly guess the secret, change to true so we render win view!
# %{
# guesses: Enum.map(st.guesses, &display_guess(&1, st.secret)),
# won: success,
# lost: not success and outOfGuesses?(st), #if we run out of guesses and success is equal to false, (just in case
# # they run out of guesses on the last turn)
# name: name,
# gameName: gameName,
# lobby: lobby,
# }
# end

# def display_guess(guess, secret) do
# guess_by_digit = String.graphemes(guess)
# secret_by_digit = String.graphemes(secret)

# # https://hexdocs.pm/elixir/Enum.html#zip/2
# Enum.zip(secret_by_digit, guess_by_digit)
# |> Enum.reduce(%{a: 0, b: 0}, fn {s, g}, %{a: bulls, b: cows} ->
# cond do
#   String.equivalent?(s, g) -> %{a: bulls + 1, b: cows}
#   Enum.member?(secret_by_digit, g) -> %{a: bulls, b: cows + 1}
#   true -> %{a: bulls, b: cows}
# end
# end)
# |> Map.put(:guess, guess)
# end

# end




defmodule Bulls.Game do
  require Logger
  @moduledoc """
  Does computations for a game of Bulls and Cows. Built base from the following
  lecture code: https://github.com/NatTuck/scratch-2021-01/blob/master/notes-4550/07-phoenix/notes.md
  """

  @type guess_display :: {
          # sets type guess to type string
          guess :: String.t(),
          a :: non_neg_integer,
          b :: non_neg_integer
        }
  @type(state :: guesses :: [String.t()], {secret :: String.t()})

  ###########################################
  ##########START ADDED STATE FUNCTIONS######
  ###########################################

  #For new player 
  def get_new_player_data() do
    %{"player" => false, "ready" => false, "guessReady" => false, "guesses" => MapSet.to_list(MapSet.new()), "wonCurrent" => false, "wins" => 0, "losses" => 0}
  end

  #For updating based on login, do not replace if user already exists
  #returns game data
  def update_for_login(gameData, username) do
    if (Map.get(gameData, username) === nil) do
      Map.put(gameData, username, get_new_player_data)
    else
      gameData
    end
  end

  #logging in, updating gamedata in state
  def login(st, username) do
    #st
    %{ st | gameData: update_for_login(st.gameData, username)}
  end

  # #Return a list of usernames for the active players
  # def accActivePlayers(keys, index, gameData) do
  #   if index < 0 do
  #     []
  #   else
  #     if gameData[Enum.at(keys,index)]["player"] and gameData[Enum.at(keys,index)]["ready"] do
  #       [Enum.at(keys,index) | accActivePlayers(keys, index - 1, gameData)]
  #     else
  #       accActivePlayers(keys, index - 1, gameData)
  #     end
  #   end
  # end

  def accActivePlayers(keys, gameData) do
    if length(keys) === 0 do
      []
    else
      if gameData[hd(keys)]["player"] and gameData[hd(keys)]["ready"] do
        [hd(keys) | accActivePlayers(tl(keys), gameData)]
      else
        accActivePlayers(tl(keys), gameData)
      end
    end
  end


  #gets usernames of players currently playing + ready
  #returns list of usernames
  def getActivePlayers(gameData) do
    #Logger.info  "*******GET ACTIVE PLAYERS************"
    #Logger.debug "st value: #{inspect(gameData)}"
    users = Map.keys(gameData)
    accActivePlayers(users, gameData)
  end

  #make the given user a player, if possible
  #returns st
  def attemptBecomePlayer(st, username) do
    Logger.info  "**=*=*****=====******"
    Logger.info  "***********************"
    Logger.debug "st value: #{inspect(st)}"
    curActivePlayers = getActivePlayers(st.gameData)
    numCurActivePlayers = length(curActivePlayers)
    if (numCurActivePlayers < 4) do
      newUserData = %{st.gameData[username] | "player" => true}
      newGameData = %{st.gameData | username => newUserData}
      Logger.debug "Returning: #{inspect(%{ st | gameData: newGameData})}"
      %{ st | gameData: newGameData}
    else
      st
    end
  end

  #Attempts to make the player
  #TESTED :) 
  def attemptMakeReady(st, username) do
    if st.gameData[username]["player"] do
      newUser = %{ st.gameData[username] | "ready" => true}
      newGameData = %{ st.gameData | username => newUser}
      %{ st | gameData: newGameData}
    else
      st
    end
  end

  # #Return a list of usernames for the players
  # def accPlayers(keys, index, gameData) do
  #   if index < 0 do
  #     []
  #   else
  #     if gameData[Enum.at(keys,index)]["player"] do
  #       [Enum.at(keys,index) | accPlayers(keys, index - 1, gameData)]
  #     else
  #       accPlayers(keys, index - 1, gameData)
  #     end
  #   end
  # end
  def accPlayers(keys, gameData) do
    #Logger.info  "Logging this text!****************"
    #Logger.debug "Keys value: #{inspect(keys)}"
    #Logger.debug "gameData value: #{inspect(gameData)}"
    if length(keys) === 0 do
      []
    else
      if gameData[hd(keys)]["player"] do
        [hd(keys) | accPlayers(tl(keys), gameData)]
      else
        accActivePlayers(tl(keys), gameData)
      end
    end
  end

  #Returns a list of all players 
  def getAllPlayers(st) do
    users = Map.keys(st.gameData)
    Logger.info  "Logging this text!****************"
    Logger.debug "Keys value: #{inspect(users)}"
    Logger.debug "gameData value: #{inspect(st.gameData)}"
    accPlayers(users, st.gameData)
  end
  
  #Checks that all players are ready
  def checkThatAllPlayersAreReady(st) do
    Logger.info  "PAY ATTENTION HERE $$$$$$$$$$$$$$"
    Logger.debug "gameData value: #{inspect(st.gameData)}"
    playersAndReady = getActivePlayers(st.gameData)
    Logger.debug "gameData value: #{inspect(st.gameData)}"
    players = getAllPlayers(st)
    Logger.debug "gameData value: #{inspect(st.gameData)}"
    if playersAndReady == nil and players == nil do
      false
    else
      if (length(players) > 0 and Enum.sort(playersAndReady) == Enum.sort(players)) do
        Logger.debug "##Players Ready: #{inspect(playersAndReady)}"
        Logger.debug "##All Players: #{inspect(players)}"
        length(players) > 0 and Enum.sort(playersAndReady) == Enum.sort(players)
      end
    end
  end 

  #Changes gameStarted to true if possible
  def startGame(st) do
    if (Game.checkThatAllPlayersAreReady(st)) do
      %{ st | gameStarted: false}
    end
  end
  
  ###########################################
  ##########END ADDED STATE FUNCTIONS########
  ###########################################
  
  def new do
    %{
      # MapSet is from lecture, can contain unique elements of any kind, no particular order
      guesses: MapSet.new(),
      secret: makeSecret(),
      gameData: %{},
      gameStarted: false,
      readyToStart: false,
      error: "",
      won: false,
    }
  end

  #need to rethink makeSecret since we no longer have while loops, loose types, etc...
  def makeSecret do
    firstNum = Enum.take_random(1..9, 1)
    remainingNum = Enum.take_random(0..9, 3)
    secret = Enum.concat(firstNum, remainingNum) |> Enum.join()
    secret
  end

  def checkUnique(guess) do
    guessAsSet = MapSet.new(guess)
    MapSet.size(guessAsSet) > 3
  end

  def checkPass(guess) do
   guessAsSet = MapSet.new(guess)
    MapSet.size(guessAsSet) === 0
    end

  def isCorrectGuess?(st, num) do
    st.secret == num
  end


  def guessResults(st, num, username) do
    #%{"player" => false, "ready" => false, "guessReady" => false, "guesses" => MapSet.to_list(MapSet.new()), "wins" => 0, "losses" => 0}
    #set to ready
    newUserData = %{st.gameData[username] | "guessReady" => true, "wonCurrent" => isCorrectGuess?(st, num)}
    guesses = st.gameData[username]["guesses"]
    if !(Enum.member?(guesses, num)) do
      newGuesses = [num | guesses]
      newNewUserData = %{newUserData | "guesses" => newGuesses}
      newGameData = %{st.gameData | username => newNewUserData}
      %{st | guesses: MapSet.put(st.guesses, num), error: "", gameData: newGameData, won: isCorrectGuess?(st, num)}
    else
      newGameData = %{st.gameData | username => newUserData}
      %{st | guesses: MapSet.put(st.guesses, num), error: "", gameData: newGameData, won: isCorrectGuess?(st, num)}
    end
  end
  
  
  def guess(st, num, username) do
    num_digits = String.graphemes(num) #graphemes was discovered from lecture, very useful!
    cond do
    checkPass(num_digits) ->
      guessResults(st,num,username)
    !checkUnique(num_digits) ->
      # Enum.uniq(num_digits) != num_digits ->
      %{st | error: "no duplicates allowed"}
      # https://hexdocs.pm/elixir/Regex.html and https://www3.ntu.edu.sg/home/ehchua/programming/howto/Regexe.html
    Regex.match?(~r/^[1-9]/, num) ->
        #%{st | guesses: MapSet.put(st.guesses, num), error: ""}
      guessResults(st, num, username)
    end
  end

  def outOfGuesses?(st) do
    MapSet.size(st.guesses) >= 8
   end


#needed help with guesses and used https://dockyard.com/blog/2016/08/05/understand-capture-operator-in-elixir
# to reference capture operator
  def view(st, name, gameName) do
    #success = isCorrectGuess?(st) #if we correctly guess the secret, change to true so we render win view!
    ready = checkThatAllPlayersAreReady(st)
    %{
      guesses: Enum.map(st.guesses, &display_guess(&1, st.secret)),
      won: st.won,
      lost: false,
      #lost: not success and outOfGuesses?(st), #if we run out of guesses and success is equal to false, (just in case
      # they run out of guesses on the last turn)
      name: name,
      gameName: gameName,
      lobby: false,
      gameData: st.gameData,
      gameStarted: st.gameStarted,
      readyToStart: ready,
      
    }
  end

  def display_guess(guess, secret) do
    guess_by_digit = String.graphemes(guess)
    secret_by_digit = String.graphemes(secret)

    # https://hexdocs.pm/elixir/Enum.html#zip/2
    Enum.zip(secret_by_digit, guess_by_digit)
    |> Enum.reduce(%{a: 0, b: 0}, fn {s, g}, %{a: bulls, b: cows} ->
      cond do
        String.equivalent?(s, g) -> %{a: bulls + 1, b: cows}
        Enum.member?(secret_by_digit, g) -> %{a: bulls, b: cows + 1}
        true -> %{a: bulls, b: cows}
      end
    end)
    |> Map.put(:guess, guess)
  end

end
