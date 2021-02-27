import React, { useState, useEffect } from 'react';
import { Container, Row, Col, Form, Table, Button, FormCheck } from 'react-bootstrap';

import { ch_join, ch_push, ch_login, ch_reset, ch_become_player, ch_become_ready } from './socket';


//need to add functions to pass in
function Lobby({state}) {
  return (
    <Container>
      <Row>
        <Col>
          <h1>Game Lobby</h1>
          <h3>Welcome to Bulls and Cows, {state.name}!</h3>
          <br></br>
        </Col>
      </Row>
      <Row>
        <p>Press the buttons to become a player (max of 4) and ready up, respectively.</p>
        <br />
      </Row>
      <Row>
        <div className="btn-holder">
        </div>
        <div className="btn-holder">
          <Button variant="primary" size="lg" onClick={() => ch_become_player()}>
            Become Player
            </Button>
        </div>
        <div className="btn-holder">
          <Button variant="primary" size="lg" onClick={() => ch_become_ready()}>
            Become Ready
            </Button>
        </div>
      </Row>
    </Container>
  );
}


/*Code for an active game being played */
function Controls({ reset, state }) {
  const [currentGuess, setCurrentGuess] = useState("");

  function makeGuess() {
    ch_push({ number: currentGuess });
    console.log(currentGuess);
  }

  /*Function based off Nat Tuck lecture code, with some tweaks to prevent more than 4 numbers */
  function updateGuess(ev) {
    let numericInput = ev.target.value;
    if (numericInput.length > 4) {
      numericInput = numericInput[numericInput.length - 1];;
    }
    setCurrentGuess(numericInput);
  }


  /*Function based off Nat Tuck lecture code, with some tweaks */
  function keyPress(ev) {
    if (ev.key === "Enter") {
      makeGuess();
    }
  }


  function updateGuessHistory(guess, index) {
    return (
      <tr key={index}>
        <td>{index + 1}</td>
        <td>{guess.guess}</td>
        <td>{guess.a} </td>
        <td>{guess.b} </td>
      </tr>
    );
  }

  function generateGuessHistoryTable() {
    return (
      <Row>
        <Col>
          <Table>
            <thead>
              <tr>
                <th>Round</th>
                <th>Guess</th>
                <th>Bulls</th>
                <th>Cows</th>
              </tr>
            </thead>
            <tbody>
              {state.guesses.map((guess, index) => updateGuessHistory(guess, index))}
            </tbody>
          </Table>
        </Col>
      </Row>
    );
  }

  return (
    <Container>
      <Row>
        <Col>
          <h1>Bulls and Cows!</h1>
          <p>(the <em>rootinest,</em> <b>tootinest</b> math game on this here corner of the internet~)</p>
        </Col>
      </Row>
      <Row>
        <Col>
        <h2>Welcome, <b>{state.name}</b></h2>
        <h2>To Game: <em>{state.gameName}</em></h2>
        </Col>
      </Row>
      <Row >
        <Col>
          <Form.Label>Guess</Form.Label>
          <Form.Control
            type="number" min="1" max="9"
            value={currentGuess}
            onChange={updateGuess}
            onKeyPress={keyPress}
          />
          <Form.Text>
            Your guess must be exactly 4 unique digits between 0-9, or the guess will not go through! You are also allowed to pass.
            </Form.Text>

          <div className="btn-holder">
            <Button variant="primary" size="lg" onClick={makeGuess}>
              Guess
            </Button>
            <div className="btn-holder"></div>
            <div className="btn-holder"></div>
            <Button variant="secondary" size="lg" onClick={makeGuess}>
              Pass
            </Button>
          </div>
        </Col>
      </Row>
      {generateGuessHistoryTable()}
    </Container>
  );
}


function Login() {
  const [name, setName] = useState("");
  const [gameName, setGameName] = useState("");

  function keyPress2(ev) {
    if (ev.key === "Enter") {
      ch_login(name, gameName);
    }
  }

  return (
    <Container>
      <Row className="top-of-login">
        <Col>
          <h1>Bulls and Cows!</h1>
          <p>(the <em>rootinest,</em> <b>tootinest</b> math game on this here corner of the internet~)</p>
          <Form.Label>Username:</Form.Label>
          <Form.Control
            type="text"
            value={name}
            onChange={(ev) => setName(ev.target.value)}
            onKeyPress={keyPress2}
          />
        </Col>
      </Row>
      <Row>
        <Col>
          <Form.Label>Game Name:</Form.Label>
          <Form.Control
            type="text"
            value={gameName}
            onChange={(ev) => setGameName(ev.target.value)}
            onKeyPress={keyPress2}
          />
        </Col>
      </Row>
      <Button
        onClick={() => ch_login(name, gameName)}>
        Join Game
      </Button>
    </Container>
  );
}

// function Winners({ state }) {
//   let jsGameData = new Map(Object.entries(state.gameData));
//   let keys = Array.from( jsGameData.keys() );
//   let winners = [];
//   for (let i = 0; i < keys.length; i++) {
//     if (jsGameData.get(keys[i]).get('wonCurrent')) {
//       winners.push(keys[i]);
//     }
//   }
//   return (
//     <h2>winners.join()</h2>
//   );

// }

function Won({ state }) {
  return (
    <Container>
      <Row>
        <Col>
          <h1>Someone won!!</h1>
          <Button
           onClick={() => ch_reset()}>
             Reset
          </Button>
        </Col>
      </Row>
    </Container>);
}


function Bulls() {
  // render function,
  // should be pure except setState
  const [state, setState] = useState({
    guesses: [],
    won: false,
    lose: false,
    name: "", //username
    gameName: "", //game name
    lobby: false, //are we in the lobby
    gameData: new Map(),
    gameStarted: false,
    readyToStart: false,
  });

  useEffect(() => ch_join(setState));

  function reset() {
    ch_reset();
  }

  if (state.name === "" || state.gameName === "" /*|| state.gameName === undefined || state.name === undefined */) {
    return (
      <Login />
    );
  }
  else if (!(state.readyToStart)) {
    return (
      <Lobby state={state}/>
    );
  }
  else if (state.won) {
    return (
      <Won state={state} />
      );
  }
  else {
        return (
        <Controls reset={reset}
           state={state}
           setState={setState} />
        );
  }

}

export default Bulls;
