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
func result(seconds: float = 0,quality: float = 1) -> Dictionary:
 var session := ShiftSession.new()
 session.start("home_game")
 session.set_progress(session.goals(),[true,true,true,true,true])
 session.set_quality([1,quality,quality,quality,1])
 session.advance(seconds)
 session.finish("completed")
 var value := session.get_result()
 session.free()
 return value
func run() -> void:
 var c := CareerProfile.new()
 c.path = "user://test-club-schedule.dat"
 DirAccess.remove_absolute(c.path)
 c.load_profile()
 check(ClubSchedule.report(c).played == 0,"sandbox wages are not home dates")
 c.start_club()
 check(ClubSchedule.fixture(0).season == 1 and ClubSchedule.fixture(0).day == 1,"new club begins on Opening Weekend")
 check(ClubSchedule.fixture(5).day == 6 and ClubSchedule.fixture(6).season == 2 and ClubSchedule.fixture(6).day == 1,"six-date seasons roll over deterministically")
 check(ClubSchedule.target_met(1,result(1080)),"early-arrival target accepts exact time boundary")
 check(not ClubSchedule.target_met(1,result(1081)),"early-arrival target rejects late prep")
 check(not ClubSchedule.target_met(4,result(0,0.9)),"finish-quality losses can miss a high score target")
 var bad := result()
 bad.reason = "ended_early"
 check(not ClubSchedule.target_met(0,bad),"unfinished prep never meets a manager target")
 for i in range(6):
  var id := Crypto.new().generate_random_bytes(16).hex_encode()
  c.claim(id,result(1100 if i == 1 else 0))
  check(ClubSchedule.report(c).played == i,"pending prep does not advance schedule")
  c.host_game(id)
 var review := ClubSchedule.report(c)
 check(review.played == 6 and review.targets == 5 and review.average == 100,"completed season records optional misses separately from prep score")
 check(review.season == 1 and review.last_met,"season review stays visible before next hosting")
 var reload := CareerProfile.new()
 reload.path = c.path
 reload.load_profile()
 check(ClubSchedule.report(reload) == review,"reload reconstructs identical season review from ledger")
 var money := c.balance
 var id := Crypto.new().generate_random_bytes(16).hex_encode()
 c.claim(id,result())
 var forecast := ClubProgress.forecast(c.club,result())
 c.host_game(id)
 check(c.balance == money+160+forecast.net,"schedule adds no currency or economic repricing")
 check(ClubSchedule.report(c).season == 2 and ClubSchedule.report(c).played == 1,"first hosted date of new season resets review only")
 c.host_game(id)
 check(ClubSchedule.report(c).played == 1,"duplicate hosting cannot advance schedule")
 DirAccess.remove_absolute(c.path)
 print("Club schedule: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
