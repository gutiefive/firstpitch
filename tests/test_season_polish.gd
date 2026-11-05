extends "res://tests/test_park_satisfaction.gd"
func run() -> void:
 root.size = Vector2i(1280,720)
 var g = load("res://scenes/main/main.tscn").instantiate()
 g.career_save_path = "user://season-polish-career.dat"
 g.settings_save_path = "user://season-polish-settings.cfg"
 g.tutorial_enabled = false
 g.autosave_enabled = false
 DirAccess.remove_absolute(g.career_save_path)
 root.add_child(g)
 await idle(12)
 var c: CareerProfile = g.shift.career
 var live: LiveMatchday = g.club.live
 var park: MatchdayPark = g.club.matchday
 var show: OpeningGates = g.club.opening
 live.set_process(false)
 park.set_process(false)
 show.set_process(false)
 g.club.join()
 var rows := PackedStringArray(["date,profile,event,prep_minutes,credits_before,credits_after,participants,satisfaction,park_bonus,purchase"])
 var seen := {}
 for date in range(6):
  var before := c.balance
  prep(g)
  var profile: String = c.data.records[-1].result.profile_id
  check(park.fielders[0].node.get_meta("team") == "OWLS" and park.runner.get_meta("team") == park.fixture.opponent,"home/opponent uniform identity follows date %d" % (date+1))
  if date == 0:
   show.update_view(20.0/47)
   show.camera.position = Vector3(2,2,-14)
   show.camera.look_at(Vector3(0,1.4,-18))
   await capture("polish-uniform")
   show.update_view(0)
  show.walk_park()
  live._process(31)
  if date == 0:
   g.player.position = live.jobs[0].point
   g.player.velocity = Vector3.ZERO
   Input.action_press("interact")
   live.advance_jobs(0.5)
   g.player.visual.animate_walk(0,0.1)
   check(live.broom.visible and g.player.visual.cleaning_pose,"held cleaning visibly equips broom and pose")
   var arm_angle: float = g.player.visual.limbs[0].rotation.x
   g.player.visual.animate_walk(0,0.12)
   check(not is_equal_approx(arm_angle,g.player.visual.limbs[0].rotation.x),"stationary sweep actually animates the arms")
   g.yaw = 2.6
   g.pitch = -0.25
   g.camera_distance = 4
   live.refresh_hud()
   await idle(8)
   await capture("polish-cleaning")
   Input.action_release("interact")
   live.advance_jobs(0.1)
   check(not live.broom.visible and not g.player.visual.cleaning_pose,"releasing cleanup stops broom animation")
  if date == 3:
   var supply: Dictionary = live.jobs[2]
   g.player.position = supply.point
   live.interact_job()
   g.player.visual.animate_walk(1,0.1)
   check(live.carrying and g.player.visual.carrying_pose and not g.player.visual.pushing_pose,"delivery uses a dedicated carry pose")
   g.yaw = 2.6
   g.pitch = -0.25
   g.camera_distance = 4
   live.refresh_hud()
   await idle(8)
   await capture("polish-carry")
  live.visit_time = 131
  live._process(0)
  var event: String = live.jobs[-1].id
  seen[event] = true
  # Completed service and prep are explicit fixtures for the economy audit.
  for job in live.jobs:
   job.state = "done"
  live.visit_time = LiveMatchday.FINAL+1
  live._process(0)
  live.end_visit()
  var report := live.service_report()
  check(not report.is_empty() and live.claim_bonus(),"date %d review settles after full visit" % (date+1))
  var purchase := "none"
  if date == 0:
   check(c.purchase("hose_nozzle"),"opening-date income affords starter hose improvement")
   purchase = "hose_nozzle"
  elif date == 2:
   check(g.club.build("snack_shack"),"third home date affords the first concession without side-job cash")
   purchase = "snack_shack"
  elif date == 3:
   check(g.club.build("bleachers"),"fourth home date affords additional seating without side-job cash")
   purchase = "bleachers"
  check(c.balance >= 0,"date %d keeps budget nonnegative" % (date+1))
  rows.append("%d,%s,%s,%d,%d,%d,%d,%d,%d,%s" % [date+1,profile,event,int(ShiftSession.PROFILES[profile].duration)/60,before,c.balance,c.club.last.attendance,report.rating,report.bonus,purchase])
 check(seen.has("lost") and seen.has("litter") and seen.has("rush"),"six-date season exposes all three event types")
 check(c.club.games == 6 and c.club.services.size() == 6 and not g.club.ownership.is_empty(),"season finale retains six rewards and ownership review")
 check(park.story_lines[-1].contains("season"),"recurring concession character recognizes season milestone")
 var copy := CareerProfile.new()
 copy.path = c.path
 check(copy.load_profile() and copy.data == c.data and copy.balance == c.balance,"full-season career v3 survives exact reload")
 var earned := 0
 for record in c.data.records:
  earned += CareerProfile.payout(record.result)
 check(c.balance == earned+int(c.club.income)-int(c.club.spent)-200,"season money reconciles including gate, service, projects and nozzle")
 var file := FileAccess.open("/tmp/firstpitch-season-polish.csv",FileAccess.WRITE)
 file.store_string("\n".join(rows)+"\n")
 file.close()
 print("SEASON_AUDIT\n","\n".join(rows))
 g.queue_free()
 await idle(4)
 DirAccess.remove_absolute("user://season-polish-career.dat")
 DirAccess.remove_absolute("user://season-polish-settings.cfg")
 print("Season polish: %d checks; %d failures" % [checks,failures])
 quit(1 if failures else 0)
