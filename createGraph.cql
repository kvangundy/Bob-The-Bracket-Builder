USING PERIODIC COMMIT 5000
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/kvangundy/Bob-The-Bracket-Builder/master/games.csv' AS line
WITH line
MERGE (t:Team {name:line.Team})
ON CREATE SET t.nameLower = toLOWER(line.Team);

USING PERIODIC COMMIT 5000
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/kvangundy/Bob-The-Bracket-Builder/master/games.csv' AS line
WITH line
MERGE (t:Team {name:line.Opponent})
ON CREATE SET t.nameLower = toLOWER(line.Opponent);

CREATE INDEX ON :Team(name);
CREATE INDEX ON :Team(nameLower);

USING PERIODIC COMMIT 5000
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/kvangundy/Bob-The-Bracket-Builder/master/games.csv' AS line
WITH line WHERE line.TeamResult = 'Win'
MATCH (home:Team {name:line.Team})
MATCH (away:Team {name:line.Opponent})
MERGE (g:Game {winner:line.Team, date:line.Date})
ON CREATE SET g.playedTimeD =  apoc.date.parse(line.Date, 'd', 'MM/dd/yy'), g.winnerLower = toLOWER(line.Team)
MERGE (home)-[r:PLAYED_IN]->(g)
SET r.scored = toINTEGER(line.TeamScore)
MERGE (away)-[rr:PLAYED_IN]->(g)
SET r.scored = toINTEGER(line.OpponentScore);

USING PERIODIC COMMIT 5000
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/kvangundy/Bob-The-Bracket-Builder/master/games.csv' AS line
WITH line WHERE line.TeamResult = 'Loss'
MATCH (home:Team {name:line.Team})
MATCH (away:Team {name:line.Opponent})
MERGE (g:Game {winner:line.Opponent, date:line.Date})
ON CREATE SET g.playedTimeD =  apoc.date.parse(line.Date, 'd', 'MM/dd/yy'), g.winnerLower = toLOWER(line.Opponent)
MERGE (home)-[r:PLAYED_IN]->(g)
SET r.scored = toINTEGER(line.TeamScore)
MERGE (away)-[rr:PLAYED_IN]->(g)
SET r.scored = toINTEGER(line.OpponentScore);

//Assigning Pythagorean Expectation

MATCH (a:Team)-[aa:PLAYED_IN]->(game:Game)<-[bb:PLAYED_IN]-(b:Team)
WITH toFloat(aa.scored*aa.scored) as team2, toFloat(bb.scored*bb.scored) as opp2, game, a,b
//Pythagorean Expectation is (points_scored^2 / (points scored^2 + points allowed^2))
WITH ((team2)/(team2+opp2)) as PyEx, game,a,b
//setting March 15th to the day before the tournament and calculating how many days ago the last game was played
WITH apoc.date.parse('03/15/17', 'd', 'MM/dd/yy') as dayBeforeTournament, game.playedTimeD as oldYear, PyEx,a,b
//assuming that "win relevance" decays linearly over 4 years or how long any part of those same teams are playing against one another represented by "weight"
WITH ((4*365.25)-(dayBeforeTournament-oldYear))/(4*365.25) as weight, PyEx, a, b
//adding up all of the weights*pythagorean expectation for a current win probability
WITH SUM(weight*PyEx) as winPower, a, b
//creating a new relationship that stores a team's given probability of defeating another team as of March 15th
MERGE (a)-[w:WINPOWER]->(b)
SET w.winPower = winPower;

