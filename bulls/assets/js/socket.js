import {Socket} from "phoenix";

let socket = new Socket(
  "/socket",
  {params: {token: ""}}
);
socket.connect();

let channel = socket.channel("game:login", {});

let state = {
  guesses: [],
  won: false,
  lost: false,
  lobby: false,
  gameData: new Map(),
  gameStarted: false,
  readyToStart: false,
};

let callback = null;

// The server sent us a new state.
function state_update(st) {
  state = st;
  if (callback) {
    callback(st);
  }
}

export function ch_join(cb) {
  callback = cb;
  callback(state);
}

//Creating a channel based on gameName
//Taking existing channel operations for .join and .on
function update_channel_by_game(gameName) {
  channel = socket.channel("game:" + gameName, {});
  channel.join()
       .receive("ok", state_update)
       .receive("error", resp => {
         console.log("Unable to join", resp)
       });
  channel.on("view", state_update);
}

//done
export function ch_login(name, gameName) {
  update_channel_by_game(gameName);
  channel.push("login", {name: name, gameName: gameName})
         .receive("ok", state_update)
         .receive("error", resp => {
           console.log("Unable to login", resp)
         });
}

//Do we need to manually pass name along? TBD
export function ch_become_player() {
  channel.push("become_player", {})
         .receive("ok", state_update)
         .receive("error", resp => {
           console.log("Unable to push", resp)
         });
}

//Do we need to manually pass name along? TBD
export function ch_become_ready() {
  channel.push("become_ready", {})
         .receive("ok", state_update)
         .receive("error", resp => {
           console.log("Unable to push", resp)
         });
}

export function ch_push(guess) {
  channel.push("guess", guess)
         .receive("ok", state_update)
         .receive("error", resp => {
           console.log("Unable to push", resp)
         });
}

export function ch_reset() {
  channel.push("reset", {})
         .receive("ok", state_update)
         .receive("error", resp => {
           console.log("Unable to push", resp)
         });
}

channel.join()
       .receive("ok", state_update)
       .receive("error", resp => {
         console.log("Unable to join", resp)
       });

channel.on("view", state_update);
