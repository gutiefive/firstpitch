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
func award(c: CareerProfile,profile: String) -> String:
 var s := ShiftSession.new()
 s.start(profile)
 s.set_progress(s.goals(),[true,true,true,true,true])
 s.advance(0)
 var id := s.attempt_id
 c.claim(id,s.get_result())
 s.free()
 return id
func date(c: CareerProfile) -> void:
 c.host_game(award(c,GameDay.profile(c.club.games)))
func career(path: String) -> CareerProfile:
 var c := CareerProfile.new()
 c.path = path
 DirAccess.remove_absolute(path)
 c.load_profile()
 c.start_club()
 return c
func run() -> void:
 var c := career("user://ownership-career.dat")
 check(ClubOwnership.review(c).is_empty(),"ownership review waits for six hosted home dates")
 for i in range(6):
  date(c)
 var review := ClubOwnership.review(c)
 check(review.season == 1 and review.targets == 6 and review.fans == 168,"first finale reviews exact season results and fans")
 check(review.earnings == c.balance and review.capacity == 120,"season earnings reconcile to prep, gate and priorities without invented rewards")
 check(review.objective.project == "bleachers" and review.objective.fans == 248,"ownership asks for a concrete project and eighty more supporters")
 check(review.text.contains("Mara:") and review.text.contains("Season 2 objective"),"review includes manager feedback and next-season goal")
 check(not review.achieved,"new ownership target begins unfinished")
 var old_budget := c.balance
 check(c.purchase_stadium("bleachers"),"club can invest after the finale")
 var after := ClubOwnership.review(c)
 check(after.objective == review.objective and after.fans == review.fans and after.earnings == review.earnings,"later construction cannot rewrite the closing review or goal")
 award(c,"full")
 check(ClubOwnership.review(c).objective == review.objective,"side contracts do not change ownership objectives")
 for i in range(4):
  date(c)
 check(ClubOwnership.review(c).achieved,"next-season progress recognizes new supporters and the requested project")
 for i in range(2):
  date(c)
 after = ClubOwnership.review(c)
 check(after.season == 2 and after.previous.contains("MET"),"following finale freezes successful previous objective")
 check(after.objective.project == "snack_shack","next ownership objective advances to the next missing project")
 var copy := CareerProfile.new()
 copy.path = c.path
 copy.load_profile()
 check(ClubOwnership.review(copy) == after,"relaunch recreates identical ownership review and goal")
 var late := career("user://ownership-late.dat")
 for i in range(12):
  date(late)
 var missed := ClubOwnership.review(late)
 check(missed.previous.contains("MISSED"),"missed project is reported at the target season's deadline")
 late.purchase_stadium("bleachers")
 check(ClubOwnership.review(late).previous == missed.previous,"buying after the deadline cannot retroactively satisfy ownership")
 check(c.balance == old_budget-600+450+int(c.club.income)-1496+960,"ownership review never awards or removes currency")
 var end := ClubProgress.initial()
 end.fans = 10000
 end.buildings = PackedStringArray(ClubProgress.PROJECTS.keys())
 var all_tools := PackedStringArray(CareerProfile.UPGRADES.keys())
 var goal := ClubOwnership.objective(end,all_tools)
 check(goal.fans == 10000 and goal.targets == 4,"fully built clubs receive capped fan and consistency targets")
 check(not ClubOwnership.met(goal,end,all_tools,3) and ClubOwnership.met(goal,end,all_tools,4),"consistency objective respects exact target boundary")
 var partial_tools := PackedStringArray()
 goal = ClubOwnership.objective(end,partial_tools)
 check(not goal.tool.is_empty() and not ClubOwnership.met(goal,end,partial_tools,6),"finished stadiums can still receive a concrete tool objective")
 DirAccess.remove_absolute(c.path)
 DirAccess.remove_absolute(late.path)
 print("Club ownership: %d checks; %d failures" % [checks,failures])
 quit(1 if failures else 0)
