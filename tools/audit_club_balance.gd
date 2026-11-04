extends SceneTree
# Deterministic progression audit, not a human playthrough. No files are written.
const ROUTES := {
 "tools_first":["hose_nozzle","wide_deck","bleachers","snack_shack","grandstand","wide_drag","guide_wheel","grill_stand","scoreboard","video_board"],
 "seats_first":["bleachers","snack_shack","hose_nozzle","wide_deck","grandstand","wide_drag","guide_wheel","grill_stand","scoreboard","video_board"],
 "nozzle_then_seats":["hose_nozzle","bleachers","snack_shack","wide_deck","grandstand","wide_drag","guide_wheel","grill_stand","scoreboard","video_board"]
}
func _initialize() -> void:
 for finish_quality in [1.0,0.75]:
  for strategy in ROUTES:
   var state := ClubProgress.initial()
   state.active = true
   var budget := 0
   var tools := PackedStringArray()
   var wages := 0
   print("ROUTE ",strategy," finish quality ",finish_quality)
   for day in range(1,19):
    var profile := GameDay.profile(day-1)
    var shift := ShiftSession.new()
    shift.start(profile)
    shift.set_progress(shift.goals(),[true,true,true,true,true])
    shift.set_quality([1.0,finish_quality,finish_quality,finish_quality,1.0])
    shift.advance(minf(1000,float(ShiftSession.PROFILES[profile].duration)-1))
    var result := shift.get_result()
    shift.free()
    assert(CareerProfile.valid_result(result),"audit requires a valid frozen shift result")
    var wage := CareerProfile.payout(result)
    wages += wage
    var receipt := ClubProgress.forecast(state,result)
    budget += wage+receipt.net+int(receipt.get("priority_bonus",0))
    state.fans = receipt.fans_after
    state.games += 1
    var options: Array = ROUTES[strategy]
    for id in options:
     if CareerProfile.UPGRADES.has(id):
      if id in tools:
       continue
      var item: Dictionary = CareerProfile.UPGRADES[id]
      # Lifetime rank includes retained earnings; this route spends only on upgrades.
      var lifetime: int = wages+int(state.income)+receipt.net+int(receipt.get("priority_bonus",0))
      if budget >= item.cost and lifetime >= int(item.get("minimum_earnings",0)):
       budget -= int(item.cost)
       tools.append(id)
       print("  Date %d: %s, %d cr left" % [day,id,budget])
      break
     if id in state.buildings:
      continue
     if ClubProgress.project_ready(state,id) and budget >= ClubProgress.PROJECTS[id].cost:
      budget -= int(ClubProgress.PROJECTS[id].cost)
      state.capacity += int(ClubProgress.PROJECTS[id].seats)
      state.buildings.append(id)
      print("  Date %d: %s, %d cr left" % [day,id,budget])
     break
    state.income += receipt.net+int(receipt.get("priority_bonus",0))
 quit()
