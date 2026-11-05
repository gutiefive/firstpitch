class_name ParkSatisfaction
extends RefCounted
static func event_for(date: int,buildings: PackedStringArray) -> String:
 if date%3 == 0:
  return "litter"
 if date%3 == 1 and ("snack_shack" in buildings or "grill_stand" in buildings):
  return "rush"
 return "lost"
static func opportunities(state: Dictionary) -> PackedStringArray:
 var ids := PackedStringArray(["spill","eli"])
 if "snack_shack" in state.buildings or "grill_stand" in state.buildings:
  ids.append("supply")
 ids.append(event_for(int(state.games),state.buildings))
 return ids
# Career-v3 settlement rules: retain these weights for existing service events.
static func evaluate(state: Dictionary,input: Variant) -> Dictionary:
 if not input is Dictionary or input.size() != 4 or not input.has_all(["seconds","queue","completed","buildings"]):
  return {}
 if typeof(input.seconds) != TYPE_INT or typeof(input.queue) != TYPE_INT or not input.completed is PackedStringArray or not input.buildings is PackedStringArray:
  return {}
 if input.seconds < 30 or input.seconds > 3600 or input.queue < 0 or input.queue > input.seconds or state.last.is_empty():
  return {}
 var owned := {}
 var capacity := ClubProgress.START_CAPACITY
 for id in input.buildings:
  if id not in state.buildings or owned.has(id) or not ClubProgress.PROJECTS.has(id):
   return {}
  owned[id] = true
  capacity += int(ClubProgress.PROJECTS[id].seats)
 for id in state.get("host_buildings",PackedStringArray()):
  if id not in input.buildings:
   return {}
 var ids := opportunities({"games":state.games,"buildings":input.buildings})
 var seen := {}
 for id in input.completed:
  if id not in ids or seen.has(id):
   return {}
  seen[id] = true
 var field := floori(float(state.last.score)*0.25)
 var comfort := clampi(12-floori(6.0*int(state.last.attendance)/maxi(1,capacity)),0,12)
 var amenities := mini(12,input.buildings.size()*2)
 var service := floori(20.0*input.completed.size()/ids.size())
 var queue := mini(10,int(input.queue)/12)
 var rating := clampi(35+field+comfort+amenities+service-queue,0,100)
 return {"rating":rating,"stars":mini(5,1+rating/20),"bonus":maxi(0,(rating-50)/2) if rating >= 60 else 0,"fans":mini(10000-int(state.fans),maxi(0,(rating-50)/15)) if rating >= 60 else 0,"field":field,"comfort":comfort,"amenities":amenities,"service":service,"queue_penalty":queue,"completed":input.completed.size(),"opportunities":ids.size()}
static func text(report: Dictionary) -> String:
 if report.is_empty():
  return "Finish a live game with at least 30 seconds on foot to earn a park review."
 return "%d / 100 satisfaction · %d / 5 stars\nWelcome +35 · Field +%d · Seating +%d · Amenities +%d · Service +%d · Queue pressure −%d\n%d / %d jobs handled · Park bonus %d cr · +%d repeat supporters" % [report.rating,report.stars,report.field,report.comfort,report.amenities,report.service,report.queue_penalty,report.completed,report.opportunities,report.bonus,report.fans]
