extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool,message: String) -> void:
 checks += 1
 if ok:
  print("PASS: ",message)
 else:
  failures += 1
  push_error(message)
func _initialize() -> void:
 call_deferred("run")
func result(profile: String,seconds: float = 0,quality: float = 1) -> Dictionary:
 var s := ShiftSession.new()
 s.start(profile)
 s.set_progress(s.goals(),[true,true,true,true,true])
 var q := [1.0,1.0,1.0,1.0,1.0]
 if GameDay.TYPES.has(profile):
  q[GameDay.TYPES[profile].job] = quality
 s.set_quality(q)
 s.advance(seconds)
 var value := s.get_result()
 s.free()
 return value
func award(c: CareerProfile,value: Dictionary) -> String:
 var id := Crypto.new().generate_random_bytes(16).hex_encode()
 c.claim(id,value)
 return id
func run() -> void:
 check(GameDay.profile(0) == "home_game" and GameDay.profile(1) == "home_hot" and GameDay.profile(2) == "home_rain" and GameDay.profile(3) == "home_double","opening day leads into three rotating conditions")
 check(GameDay.profile(4) == "home_hot" and GameDay.profile(7) == "home_hot","condition rotation continues across season boundaries")
 var c := CareerProfile.new()
 c.path = "user://test-game-day-career.dat"
 DirAccess.remove_absolute(c.path)
 c.load_profile()
 c.start_club()
 var opener := result("home_game")
 check(CareerProfile.payout(opener) == 160 and GameDay.bonus(opener) == 0,"original prep wages and manager-free opener remain unchanged")
 c.host_game(award(c,opener))
 check(c.balance == 244 and c.club.income == 84,"old home-game economics remain exact")
 for profile in GameDay.TYPES:
  var rule: Dictionary = GameDay.TYPES[profile]
  var completed := result(profile,rule.seconds)
  check(CareerProfile.valid_result(completed) and ClubProgress.eligible(completed),"new condition result validates and can host: "+profile)
  check(ClubSchedule.target_met(0,completed),"new season review uses the same manager priority: "+profile)
  check(GameDay.bonus(completed) == rule.bonus,"manager target accepts exact time boundary: "+profile)
  check(GameDay.bonus(result(profile,rule.seconds+1)) == 0,"manager target rejects late finish: "+profile)
  if rule.job != 4:
   check(GameDay.bonus(result(profile,0,0.94)) == 0,"manager target rejects poor priority-job quality: "+profile)
  var id := award(c,completed)
  var before := c.balance
  var expected := ClubProgress.forecast(c.club,completed)
  var settlement := c.host_game(id)
  check(settlement.status == "hosted" and c.balance == before+expected.net+rule.bonus,"hosting commits gate plus manager bonus atomically: "+profile)
  check(c.club.last.priority_bonus == rule.bonus and GameDay.recap(c).contains("manager bonus %d" % rule.bonus),"recap displays frozen bonus: "+profile)
  before = c.balance
  check(c.host_game(id).status == "recorded" and c.balance == before,"duplicate hosting cannot pay priority bonus twice: "+profile)
 var frozen := result("home_hot",1100)
 var id := award(c,frozen)
 c.claim(id,result("home_hot"))
 var preview := ClubProgress.forecast(c.club,frozen)
 var before := c.balance
 c.path = "user://missing-game-day-folder/career.dat"
 check(c.host_game(id).status == "error" and c.balance == before and not c.club.hosted.has(id),"failed settlement write preserves pending game and budget")
 c.path = "user://test-game-day-career.dat"
 c.host_game(id)
 check(c.club.last.priority_bonus == 0 and c.balance == before+preview.net,"improved replay cannot replace frozen missed priority")
 var restored := CareerProfile.new()
 restored.path = c.path
 restored.load_profile()
 check(restored.data == c.data and restored.club == c.club and restored.balance == c.balance,"reload reconstructs all condition bonuses and exact finances")
 check(GameDay.recap(restored).contains("MISSED") and GameDay.recap(restored).contains("already received"),"recap distinguishes missed request and previously paid wages")
 check(GameDay.investment_text(restored).contains("Next tool:") and GameDay.investment_text(restored).contains("fans"),"next investments show shared-budget and fan progress")
 var bad := c.data.duplicate(true)
 bad.club.events[-1].priority_bonus = 999
 check(not c.validate(bad),"serialized bonus injection is rejected by strict ledger replay")
 DirAccess.remove_absolute(c.path)
 print("Game day: %d checks; %d failures" % [checks,failures])
 quit(1 if failures else 0)
