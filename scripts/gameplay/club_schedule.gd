class_name ClubSchedule
extends RefCounted
# Presentation derived only from committed hosting order and frozen prep results.
# No new currency, save fields or changes to the version-2 economic ledger.
const DATES := [
	{
		"opponent": "Mill Creek Foxes",
		"event": "Opening weekend",
		"target": 85,
		"minutes": 20,
		"brief": "Mara: Give our regulars a field they can be proud of. Aim for an 85 prep score."
	},
	{
		"opponent": "Riverbend Otters",
		"event": "Family afternoon",
		"target": 85,
		"minutes": 18,
		"brief": "Mara: Families arrive early today. Finish with two minutes to spare and an 85 prep score."
	},
	{
		"opponent": "Pine Ridge Bears",
		"event": "Rivalry night",
		"target": 90,
		"minutes": 20,
		"brief": "Mara: The neighbors are visiting. A 90 prep score will give us something to brag about."
	},
	{
		"opponent": "Maple Falls Robins",
		"event": "Community appreciation",
		"target": 90,
		"minutes": 18,
		"brief": "Mara: The volunteers have brought their families. Aim for 90 with two minutes left."
	},
	{
		"opponent": "Riverbend Otters",
		"event": "Friday under the lights",
		"target": 95,
		"minutes": 20,
		"brief": "Mara: The field is our calling card tonight. Let's aim for a 95 prep score."
	},
	{
		"opponent": "Pine Ridge Bears",
		"event": "Home finale",
		"target": 95,
		"minutes": 17,
		"brief": "Mara: Finish the home season strong: a 95 prep score with three minutes to spare."
	}
]


static func fixture(index: int) -> Dictionary:
	var date: Dictionary = DATES[posmod(index, DATES.size())].duplicate(true)
	date.season = floori(float(index) / DATES.size()) + 1
	date.day = posmod(index, DATES.size()) + 1
	return date


static func target_met(index: int, result: Dictionary) -> bool:
	if GameDay.TYPES.has(result.get("profile_id", "")):
		return GameDay.priority_met(result)
	var date := fixture(index)
	return (
		ClubProgress.eligible(result)
		and float(result.score) >= date.target
		and float(result.elapsed_seconds) <= int(date.minutes) * 60
	)


static func title(index: int) -> String:
	var date := fixture(index)
	return (
		"Season %d · Home date %d / %d · vs %s\n%s"
		% [date.season, date.day, DATES.size(), date.opponent, date.event]
	)


static func report(career: CareerProfile) -> Dictionary:
	var played: Array = []
	var by_id := {}
	for record in career.data.records:
		by_id[record.id] = record.result
	if career.club_started():
		for event in career.data.club.events:
			if event.type == "game":
				played.append(by_id[event.id])
	var count := played.size()
	# A completed season remains on screen until the first game of the next one.
	var start := maxi(0, floori(float(maxi(0, count - 1)) / DATES.size()) * DATES.size())
	var targets := 0
	var score := 0.0
	for i in range(start, count):
		targets += int(target_met(i, played[i]))
		score += float(played[i].score)
	return {
		"season": floori(float(start) / DATES.size()) + 1,
		"played": count - start,
		"targets": targets,
		"average": score / maxi(1, count - start),
		"last_met": count > 0 and target_met(count - 1, played[count - 1])
	}
