extends SceneTree
var checks := 0
var failures := 0


func check(ok: bool, message: String) -> void:
	checks += 1
	if ok:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)


func _initialize() -> void:
	call_deferred("run")


func result(profile: String = "home_game", complete: bool = true, quality: float = 1) -> Dictionary:
	var s := ShiftSession.new()
	s.start(profile)
	s.set_progress(
		s.goals() if complete else [0, 0, 0, 0, 0],
		[true, true, true, true, true] if complete else [false, false, false, false, false]
	)
	s.set_quality([1, quality, quality, quality, 1])
	s.finish("completed" if complete else "ended_early")
	var value := s.get_result()
	s.free()
	return value


func award(c: CareerProfile, profile: String = "home_game") -> String:
	var id := Crypto.new().generate_random_bytes(16).hex_encode()
	c.claim(id, result(profile))
	return id


func run() -> void:
	var c := CareerProfile.new()
	c.path = "user://test-club-progress.dat"
	DirAccess.remove_absolute(c.path)
	c.load_profile()
	check(
		not c.club_started() and c.club.fans == 48,
		"existing sandbox career starts without forcing club enrollment"
	)
	check(
		c.host_game("invalid").status == "error" and not c.purchase_stadium("bleachers"),
		"club rewards and buildings require enrollment"
	)
	award(c, "full")
	c.purchase("wide_deck")
	var old_balance := c.balance
	var old_earned := c.earned
	var legacy := c.data.duplicate(true)
	c.path = "user://missing-club-directory/career.dat"
	check(not c.start_club() and c.data == legacy, "failed enrollment write leaves old career untouched")
	c.path = "user://test-club-progress.dat"
	check(
		c.start_club() and c.data.version == 2 and c.balance == old_balance and c.earned == old_earned,
		"club enrollment preserves old wages, spending and tool purchases"
	)
	check(
		c.club.games == 0 and c.club.income == 0 and c.club.capacity == 120,
		"old shifts receive no retroactive crowds or ticket money"
	)
	check(not c.start_club(), "club enrollment cannot reset an existing story")
	var unfinished := Crypto.new().generate_random_bytes(16).hex_encode()
	c.claim(unfinished, result("home_game", false))
	check(
		not c.pending_home_game(unfinished) and c.host_game(unfinished).status == "error",
		"incomplete home prep cannot generate fans or gate income"
	)
	var id := award(c)
	check(
		c.club.pending == id and c.pending_home_game(id), "completed home prep creates a durable pending game"
	)
	var before := c.balance
	var pending_data := c.data.duplicate(true)
	c.path = "user://missing-club-directory/career.dat"
	check(
		(
			c.host_game(id).status == "error"
			and c.data == pending_data
			and c.balance == before
			and c.club.fans == 48
		),
		"failed game settlement changes neither supporters nor ticket money"
	)
	c.path = "user://test-club-progress.dat"
	var hosted := c.host_game(id)
	check(
		hosted.status == "hosted" and hosted.receipt.attendance == 48 and hosted.receipt.net == 84,
		"first home date derives attendance and net income from the fan base"
	)
	check(
		c.balance == before + 84 and c.club.fans == 68 and c.club.games == 1,
		"hosting commits fans and income together"
	)
	var after := c.data.duplicate(true)
	check(
		c.host_game(id).status == "recorded" and c.data == after,
		"the same prep attempt cannot host or pay twice"
	)
	check(
		c.claim(id, result()).status == "recorded" and c.data == after,
		"rewinding a hosted attempt cannot duplicate its prep wages"
	)
	var bad := after.duplicate(true)
	bad.club.events.append(bad.club.events[-1].duplicate(true))
	check(not c.validate(bad), "duplicate home-game settlements are rejected")
	bad = after.duplicate(true)
	bad.club.events[-1].net = 100000
	check(not c.validate(bad), "serialized income cannot override replayed ticket economics")
	bad = after.duplicate(true)
	bad.club.fans = 10000
	check(not c.validate(bad), "serialized fan totals cannot bypass event replay")
	bad = after.duplicate(true)
	bad.club.events[-1].records = 0
	check(not c.validate(bad), "a game cannot use a prep result outside its recorded ledger prefix")
	bad = after.duplicate(true)
	bad.club.events.append(
		{"type": "build", "id": "grandstand", "records": bad.records.size(), "tools": bad.upgrades.size()}
	)
	check(not c.validate(bad), "fan and prerequisite locks protect stadium construction")
	check(not c.purchase_stadium("bleachers"), "a wallet cannot bypass a project's supporter requirement")
	for i in range(2):
		c.host_game(award(c))
	check(
		c.club.fans == 108 and c.club.games == 3, "good repeated home dates grow support without idle income"
	)
	before = c.balance
	var state := c.data.duplicate(true)
	c.path = "user://missing-club-directory/career.dat"
	check(
		not c.purchase_stadium("bleachers") and c.data == state and c.balance == before,
		"failed building write preserves budget, capacity and event history"
	)
	c.path = "user://test-club-progress.dat"
	check(
		c.purchase_stadium("bleachers") and c.club.capacity == 240 and c.balance == before - 600,
		"bleachers spend real club money and add 120 seats"
	)
	check(
		c.club.fans == 108 and not c.purchase_stadium("bleachers"),
		"seating does not invent fans or charge twice"
	)
	var fans: int = c.club.fans
	var games: int = c.club.games
	award(c, "full")
	check(
		c.club.fans == fans and c.club.games == games,
		"side contracts fund the budget without simulating home games"
	)
	check(c.purchase_stadium("snack_shack"), "earned side-work money can fund the snack shack")
	hosted = c.host_game(award(c))
	check(
		hosted.receipt.food_income == hosted.receipt.attendance and hosted.receipt.fans_gained == 23,
		"amenities improve per-attendee income and word-of-mouth growth"
	)
	while c.club.fans < 200:
		c.host_game(award(c))
	before = c.balance
	check(
		c.purchase_stadium("grandstand") and c.club.capacity == 480 and c.balance == before - 1400,
		"covered grandstand requires earlier projects and adds 240 seats"
	)
	hosted = c.host_game(award(c))
	check(
		hosted.receipt.ticket_income == hosted.receipt.attendance * 5 and hosted.receipt.fans_gained == 28,
		"covered seating raises ticket yield and fan growth"
	)
	check(
		ClubProgress.chapter(c.club).title.begins_with("Chapter 5"),
		"stadium investments advance the manager's story chapters"
	)
	var expected := 0
	for record in c.data.records:
		expected += CareerProfile.payout(record.result)
	expected += int(c.club.income) - int(c.club.spent)
	for tool in c.data.upgrades:
		expected -= int(CareerProfile.UPGRADES[tool].cost)
	check(c.balance == expected, "shared budget reconciles wages, gate profit, tool costs and stadium costs")
	var restored := CareerProfile.new()
	restored.path = c.path
	check(
		(
			restored.load_profile()
			and restored.data == c.data
			and restored.balance == c.balance
			and restored.club == c.club
		),
		"career restart replays identical story, fans, stadium and money"
	)
	var high := ClubProgress.forecast(c.club, result("home_game", true, 1))
	var low := ClubProgress.forecast(c.club, result("home_game", true, 0.7))
	check(
		high.attendance > low.attendance and high.net > low.net and high.fans_gained > low.fans_gained,
		"finish quality influences crowd, profit and fan growth"
	)
	var packed := restored.data.duplicate(true)
	packed.club.events[-1].tools = -1
	check(not restored.validate(packed), "invalid tool-prefix counts are rejected")
	var demand := ClubProgress.initial()
	demand.fans = 200
	var small := ClubProgress.forecast(demand, result())
	demand.capacity = 240
	var expanded := ClubProgress.forecast(demand, result())
	check(
		small.attendance == 120 and expanded.attendance == 200 and expanded.net > small.net,
		"seating caps a sold-out crowd and expanding capacity converts demand into more money"
	)
	var rewind := CareerProfile.new()
	rewind.path = "user://test-club-rewind.dat"
	DirAccess.remove_absolute(rewind.path)
	rewind.load_profile()
	rewind.start_club()
	var rewind_id := Crypto.new().generate_random_bytes(16).hex_encode()
	var original := result("home_game", true, 0.85)
	rewind.claim(rewind_id, original)
	var forecast := ClubProgress.forecast(rewind.club, original)
	rewind.claim(rewind_id, result())
	var replayed := rewind.host_game(rewind_id)
	check(
		(
			replayed.receipt.score == original.score
			and replayed.receipt.net == forecast.net
			and rewind.balance == CareerProfile.payout(original) + int(forecast.net)
		),
		"rewinding to higher prep quality cannot improve an already recorded game's crowd or revenue"
	)
	DirAccess.remove_absolute(rewind.path)
	DirAccess.remove_absolute(c.path)
	print("Club progression: ", checks, " checks; ", failures, " failures")
	quit(1 if failures else 0)
