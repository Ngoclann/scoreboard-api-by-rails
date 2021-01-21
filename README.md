# Scoreboard API
At the office we love playing ping pong. But currently we have a problem, we don't have any scoreboard where we can register all matches and points per player.

We'd love to have a  **restful**  API that we could use to track each game and points.
## The overview
-   This can use  _any_  framework or library, but it must be in Ruby.
-   It should accept and respond JSON format.
-   This can use any database or storage strategy.
-   The API should be live when be delivered, can be set a free  [heroku](http://heroku.com/)  account.
-   Adding tests is optional, but it will add extra points. (This can use any testing library).
-   Fork this repo to my own github account and work there.

## Database

In addition to basic infomation (id, name, count, point, etc.), model **Game** have status `isPlaying`.

> This status will be a flag condition to start game or end game.

**Player** also have status `isLogin` to make sure player login before start game and status `isAdmin` to make sure authorization is active.

It also have a model **Log** to record every single action in game. When you access game action `get details`, `score`, `reset point` and `end game`, you will need information of Log to find last score of players in one game. Each record of Log table have 2 boolean `isP1LastPoint` & `isP2LastPoint` active like *pointer*.

**Blacklist** record revoked token by `log out` action. Records in blacklist will be automatically deleted after 24 hour by a trigger function.

## Authentication & Authorization
Before request any action in **The specs** part below (except `leaderboard`), you have to request authentication action. But only admin can access `start game`, `reset point` and `end game` (admin organize game).  To request authentication, you need token get from login action. This token will expire after 24 hour.
#### Example
```
POST /v1/auth/login

Request:
{
    "username" : "pipi",
    "password" : "pipi"
}

Response:
{ 
    "token": "eyJhbGciOiJIUzI1NiJ9.eyJpZCI6MzUsImV4cCI6MTYxMTA3NDIwOH0.nhHRzVnzqGV84ov3W7A7GL39dkAjeednlK9WVUEd5Uw",
	"exp": "01-19-2021 23:36"
}
```
Use response token with Bearer Authorization in any request in [POSTMAN](https://www.postman.com/).
But when you log out, this token will be added to `blacklist` in database. You will no longer be able to request authentication by the token in the blacklist.
## The specs
The actions you should be able to do with the API are these:
-   Create a player
-   Update a player
-   Delete a player
-   Get player info
-   Get all players
-   Start a game
-   Score a point for a player in a game
-   Reset a point scored previously
-   End a game
-   Get game details
-   Get leaderboard
-   Log in and Log out
	- 
The first four actions are self explanatory, a  `player`  would have  `:name`,  `point`, `:wins_count`  and  `:loses_count`  only. For the other actions below is the detailed explanation.

When request get all players, list response render paging by [pagy](https://github.com/ddnexus/pagy). There are 20 records each page.
### Start a game
Starting a game would be as creating a new game, you'll need to send the two users' id that are playing.
#### Example
```
POST /v1/games

Request:
{
    "players" : {
        "A" : 3,
        "B" : 1,
    }
}

Response:
{ 
    "game": { 
        "id": 4,
        "players": [
            { "id": 3, "points": 0 },
            { "id": 1, "points": 0 }
        ],
        "winner": 0 
    } 
}
```
### Score a point for a player in a game
This would be used when a user scores a point in a game. You'll need to send the id of the game as well as the user's id that scored the point.

#### Example

```
POST /v1/games/4/score

Request:
{
    "player_id": 3
}

Response:
{ 
    "game": 
    { 
        "id": 4,
        "players": [
            { "id": 3, "points": 1 },
            { "id": 1, "points": 0 }
        ],
        "winner": 0 
    } 
}
```
### Reset a point scored previously
This is useful for when someone scores and in the end it wasn't a valid point or something. You need to send the id of the player that scored the point. It works like **Undo** and **Redo**. It should validate if you try to *reset a score of zero*.

#### Example

```
DELETE /games/45/reset_point

Request:
{
    "player_id": 3
    "step": 2
    "choice": "undo"
}

Response:
{ 
    "message":  "Reset score of player 1 to 20"
}
```
### End a game
Ending a game should *freeze the game*, that means no more scores can be registered and it will add the stats to the player. It should return the winner of the game based on the current registered points.

#### Example

```
PUT /games/4/end

Response:
{ 
    "game": { 
        "id": 4,
        "players": [
            { "id": 3, "points": 7 },
            { "id": 1, "points": 5 }], 
        "winner": 3 
    }
}
```
### Get game details
This is only for informational purposes, should return the game details.

#### Example

```
GET /games/45

Response:
{ 
    "game": { 
        "id": 45,
        "players": [
            { "id": 3, "points": 7 },
            { "id": 1, "points": 5 }
        ],
        "winner": 3 
    } 
}
```
### Get leaderboard
This is the list of all the users ordered by their  `wins_count - loses_count`, that means the one with most wins could not be the top leaderboard, but the one that also doesn't have too many loses.

#### Example

```
GET /leaderboard

Response:
{ 
    "players": [
        {   "id": 3, "name": "Fer", "wins_count": 50, "loses_count": 3 },
        {   "id": 1, "name": "Adrian", "wins_count": 53, "loses_count": 10 },
        {   "id": 19, "name": "Chava", "wins_count": 45, "loses_count": 20 }
    ] 
}
```
### Error responses
The API should respond with appropiate [status codes and messages](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html). 

> All requests served correctly should respond with **2xx**.

The requests that fails should return a correct status code according to the description of each one.