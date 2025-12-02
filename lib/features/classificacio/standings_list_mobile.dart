import 'package:flutter/material.dart';

class TeamStanding {
  final int pos;
  final String name;
  final int played;
  final int won;
  final int lost;
  final int pf;
  final int pc;
  final int points;
  final List<bool> streak; // true=win, false=loss

  TeamStanding({
    required this.pos,
    required this.name,
    required this.played,
    required this.won,
    required this.lost,
    required this.pf,
    required this.pc,
    required this.points,
    required this.streak,
  });
}

final List<TeamStanding> mockStandings = [
  TeamStanding(
    pos: 1,
    name: 'CB ARTÉS',
    played: 11,
    won: 10,
    lost: 1,
    pf: 728,
    pc: 655,
    points: 21,
    streak: [true, true, true, true, true],
  ),
  TeamStanding(
    pos: 2,
    name: 'INTERSPORT OLARIA - SAMÀ VILANOVA SAM',
    played: 11,
    won: 9,
    lost: 2,
    pf: 762,
    pc: 707,
    points: 20,
    streak: [true, true, true, true, false],
  ),
  TeamStanding(
    pos: 3,
    name: 'AE MINGUELLA A - PURE CUISINE',
    played: 11,
    won: 9,
    lost: 2,
    pf: 762,
    pc: 676,
    points: 20,
    streak: [true, true, true, false, true],
  ),
  TeamStanding(
    pos: 4,
    name: 'JAC SANTS BARCELONA',
    played: 11,
    won: 7,
    lost: 4,
    pf: 748,
    pc: 716,
    points: 18,
    streak: [true, true, false, true, false],
  ),
  TeamStanding(
    pos: 5,
    name: 'SALAS CE SANT NICOLAU',
    played: 11,
    won: 7,
    lost: 4,
    pf: 757,
    pc: 698,
    points: 18,
    streak: [false, true, true, true, false],
  ),
  TeamStanding(
    pos: 6,
    name: 'UE.MONTGAT',
    played: 10,
    won: 7,
    lost: 3,
    pf: 704,
    pc: 646,
    points: 17,
    streak: [false, false, true, true, true],
  ),
  TeamStanding(
    pos: 7,
    name: 'CB MARTORELL A',
    played: 11,
    won: 6,
    lost: 5,
    pf: 787,
    pc: 774,
    points: 17,
    streak: [false, false, true, false, true],
  ),
  TeamStanding(
    pos: 8,
    name: 'CBU LLORET SAMBA HOTELS',
    played: 11,
    won: 5,
    lost: 6,
    pf: 779,
    pc: 791,
    points: 16,
    streak: [true, true, false, false, true],
  ),
];

class StandingsListMobile extends StatelessWidget {
  final List<TeamStanding> standings;
  const StandingsListMobile({super.key, required this.standings});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: standings.length,
      separatorBuilder: (_, __) => Divider(height: 1),
      itemBuilder: (context, i) {
        final team = standings[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: team.pos <= 3 ? Colors.amber : Colors.grey[300],
            child: Text(
              team.pos.toString(),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            team.name,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Text(
            'J: ${team.played}  G: ${team.won}  P: ${team.lost}  PF: ${team.pf}  PC: ${team.pc}',
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${team.points} pts',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: team.streak
                    .map(
                      (w) => Icon(
                        Icons.circle,
                        size: 10,
                        color: w ? Colors.green : Colors.red,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
