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
func result(profile: String,values: Array,reason: String = "ended_early") -> Dictionary:
 var session := ShiftSession.new()
 session.start(profile)
 session.set_progress(values,[values[0]>=100,values[1]>=100,values[2]>=100,values[3]>=100,values[4]>=100])
 session.elapsed_seconds = 30
 session.remaining_seconds = session.duration_seconds-30
 session.finish(reason)
 var value := session.get_result()
 session.free()
 return value
func id() -> String:
 return Crypto.new().generate_random_bytes(16).hex_encode()
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var career := CareerProfile.new()
 career.path = "user://test-career-unit.dat"
 DirAccess.remove_absolute(career.path)
 check(career.load_profile() and career.balance == 0 and career.rank_title() == "Rookie","new career starts with zero credits and rookie rank")
 check(not career.purchase("wide_deck") and not career.purchase("unknown"),"unaffordable and unknown upgrades cannot be purchased")
 var partial := result("training",[12.5,0,0,0,0])
 var attempt := id()
 var receipt := career.claim(attempt,partial)
 check(receipt.status == "awarded" and receipt.pay == 10 and career.balance == 10,"partial training earns proportional credits")
 partial.score = 100
 check(career.data.records[0].result.score == 10,"claimed result is a deep snapshot")
 check(career.claim(attempt,result("training",[100,100,100,100,100],"completed")).status == "recorded" and career.balance == 10,"rewinding an attempt cannot upgrade or duplicate its payout")
 check(career.claim(id(),result("full",[0,0,0,0,0])).pay == 0 and career.balance == 10,"empty work earns zero and is still finalized")
 check(career.claim("invalid",result("full",[0,0,0,0,0])).status == "error","invalid attempt identity is rejected")
 var bad := result("training",[0,0,0,0,0])
 bad.score = 99
 check(career.claim(id(),bad).status == "error","inconsistent score cannot create credits")
 var turnaround := ShiftSession.new()
 turnaround.start("doubleheader")
 turnaround.set_progress([0,75,100,75,100],[false,false,true,false,true])
 turnaround.set_quality([1,0.75,0.7,0.75,1])
 turnaround.finish("completed")
 check(CareerProfile.valid_result(turnaround.get_result()) and CareerProfile.payout(turnaround.get_result()) == 260,"doubleheader final quality score drives its payout")
 var forged := turnaround.get_result()
 forged.quality = 1.0
 check(not CareerProfile.valid_result(forged),"forged quality multiplier cannot increase payout")
 turnaround.free()
 var full := result("full",[100,100,100,100,100],"completed")
 check(career.claim(id(),full).pay == 450 and career.balance == 460,"complete full prep earns score pay and completion bonus")
 check(career.claim(id(),result("training",[25,50,50,50,100],"completed")).pay == 150,"training completion pays 150 credits")
 check(career.rank_title() == "Field Hand" and career.earned == 610,"lifetime earnings promote the crew")
 check(career.completed == 2 and career.best.full == 100 and career.best.training == 100,"records track completed jobs and separate personal bests")
 var blocked_shop := CareerProfile.new()
 blocked_shop.data = career.data.duplicate(true)
 blocked_shop.rebuild()
 blocked_shop.path = "user://missing-career-directory/shop.dat"
 check(not blocked_shop.purchase("wide_deck") and blocked_shop.balance == 610 and not blocked_shop.owns("wide_deck"),"failed purchase write preserves both wallet and equipment")
 check(career.purchase("wide_deck") and career.balance == 310 and career.owns("wide_deck"),"buying the deck spends its price once")
 check(not career.purchase("wide_deck") and career.balance == 310,"owned equipment cannot be purchased twice")
 check(career.rank_title() == "Field Hand" and career.earned == 610,"spending does not remove rank progress")
 check(career.purchase("hose_nozzle") and career.balance == 110,"second upgrade has its own price")
 var restored := CareerProfile.new()
 restored.path = career.path
 check(restored.load_profile() and restored.balance == 110 and restored.owns("wide_deck") and restored.owns("hose_nozzle"),"career and purchases restore across instances")
 check(restored.claim(attempt,result("training",[0,0,0,0,0])).status == "recorded" and restored.balance == 110,"paid identities survive restart")
 var data := career.data.duplicate(true)
 data.records.append(data.records[0].duplicate(true))
 check(not career.validate(data),"duplicate ledger identities are rejected")
 data = career.data.duplicate(true)
 data.upgrades.append("wide_deck")
 check(not career.validate(data),"duplicate upgrades are rejected")
 data = {"version":1,"records":[],"upgrades":PackedStringArray(["wide_deck"])}
 check(not career.validate(data),"unfunded upgrades cannot load")
 var before := restored.data.duplicate(true)
 restored.path = "user://missing-career-directory/career.dat"
 var retry_id := id()
 check(restored.claim(retry_id,full).status == "error" and restored.data == before,"failed reward write does not change wallet or ledger")
 restored.path = career.path
 check(restored.claim(retry_id,full).status == "awarded" and restored.claim(retry_id,full).status == "recorded" and restored.balance == 560,"failed reward can be retried and then pays exactly once")
 before = restored.data.duplicate(true)
 # This fixture intentionally damages every available copy.
 DirAccess.remove_absolute(restored.path+".bak")
 var file := FileAccess.open(restored.path,FileAccess.READ_WRITE)
 file.seek(45)
 file.store_8(255)
 file.close()
 check(not restored.load_profile() and not restored.healthy and restored.data == before,"damaged profile is kept without replacing confirmed in-memory progress")
 check(not restored.purchase("wide_deck") and restored.claim(id(),full).status == "error","damaged profiles block financial changes")
 DirAccess.remove_absolute(career.path)
 print("Career: ",checks," checks; ",failures," failures")
 quit(1 if failures else 0)
