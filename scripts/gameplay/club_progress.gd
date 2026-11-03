class_name ClubProgress
extends RefCounted
const TEAM := "Cedar Grove Owls"
const START_FANS := 48
const START_CAPACITY := 120
const STARTER_DECK := 1.8
const STARTER_DRAG := 2.2
const STARTER_WATER := 0.55
const PROJECTS := {
 "bleachers":{"title":"Community bleachers","cost":600,"fans":90,"requires":[],"seats":120,"fan_bonus":0,"ticket_bonus":0,"food":0,"detail":"Add 120 seats. Supporters need room before crowds can grow."},
 "snack_shack":{"title":"Family snack shack","cost":450,"fans":75,"requires":[],"seats":0,"fan_bonus":3,"ticket_bonus":0,"food":1,"detail":"Earn 1 cr per attendee in food profit; attract 3 extra fans per game."},
 "grandstand":{"title":"Covered grandstand","cost":1400,"fans":200,"requires":["bleachers","snack_shack"],"seats":240,"fan_bonus":5,"ticket_bonus":1,"food":0,"detail":"Add 240 seats, covered seating, 1 cr per ticket and 5 extra fans per game."}
}
static func initial() -> Dictionary:
 return {"active":false,"fans":START_FANS,"capacity":START_CAPACITY,"games":0,"income":0,"spent":0,"buildings":PackedStringArray(),"hosted":{},"last":{},"pending":"","record_start":0}
static func eligible(result: Dictionary) -> bool:
 return result.get("profile_id") == "home_game" and result.get("reason") == "completed"
static func forecast(state: Dictionary,result: Dictionary) -> Dictionary:
 var score: float = result.score
 var ticket := 4
 var food := 0
 var bonus := 0
 for id in state.buildings:
  ticket += int(PROJECTS[id].ticket_bonus)
  food += int(PROJECTS[id].food)
  bonus += int(PROJECTS[id].fan_bonus)
 var crowd := mini(state.capacity,maxi(1,floori(state.fans*(0.65+0.35*score/100))))
 var tickets := crowd*ticket
 var food_income := crowd*food
 var costs := 60+crowd
 var growth := mini(10000-int(state.fans),8+floori(score*0.12)+bonus)
 return {"game":int(state.games)+1,"score":score,"attendance":crowd,"capacity":state.capacity,"fans_before":state.fans,"fans_gained":growth,"fans_after":int(state.fans)+growth,"ticket_income":tickets,"food_income":food_income,"costs":costs,"net":maxi(0,tickets+food_income-costs)}
static func project_ready(state: Dictionary,id: String) -> bool:
 if not PROJECTS.has(id) or id in state.buildings or state.fans < int(PROJECTS[id].fans):
  return false
 for requirement in PROJECTS[id].requires:
  if requirement not in state.buildings:
   return false
 return true
static func replay(value: Variant,records: Array,tools: PackedStringArray) -> Dictionary:
 if not value is Dictionary or not value.has_all(["record_start","tool_start","events"]) or value.size() != 3:
  return {}
 if typeof(value.record_start) != TYPE_INT or typeof(value.tool_start) != TYPE_INT or not value.events is Array or value.events.size() > 2003:
  return {}
 if value.record_start < 0 or value.record_start > records.size() or value.tool_start < 0 or value.tool_start > tools.size():
  return {}
 var pay := [0]
 var tool_cost := [0]
 var by_id := {}
 for i in range(records.size()):
  var record: Dictionary = records[i]
  pay.append(int(pay[-1])+CareerProfile.payout(record.result))
  by_id[record.id] = i
 for id in tools:
  if not CareerProfile.UPGRADES.has(id):
   return {}
  tool_cost.append(int(tool_cost[-1])+int(CareerProfile.UPGRADES[id].cost))
 if int(pay[value.record_start])-int(tool_cost[value.tool_start]) < 0:
  return {}
 var state := initial()
 state.active = true
 state.record_start = value.record_start
 var previous_records: int = value.record_start
 var previous_tools: int = value.tool_start
 for event in value.events:
  if not event is Dictionary or not event.has_all(["type","id","records","tools"]) or event.size() != 4 or not event.id is String:
   return {}
  if typeof(event.records) != TYPE_INT or typeof(event.tools) != TYPE_INT or event.records < previous_records or event.records > records.size() or event.tools < previous_tools or event.tools > tools.size():
   return {}
  previous_records = event.records
  previous_tools = event.tools
  var funds := int(pay[event.records])-int(tool_cost[event.tools])+int(state.income)-int(state.spent)
  if funds < 0:
   return {}
  if event.type == "game":
   if not by_id.has(event.id) or state.hosted.has(event.id):
    return {}
   var index: int = by_id[event.id]
   if index < value.record_start or index >= event.records or not eligible(records[index].result):
    return {}
   var receipt := forecast(state,records[index].result)
   state.games = receipt.game
   state.fans = receipt.fans_after
   state.income += receipt.net
   state.hosted[event.id] = receipt.duplicate(true)
   state.last = receipt
  elif event.type == "build":
   if not project_ready(state,event.id) or funds < int(PROJECTS[event.id].cost):
    return {}
   state.spent += int(PROJECTS[event.id].cost)
   state.capacity += int(PROJECTS[event.id].seats)
   state.buildings.append(event.id)
  else:
   return {}
 for i in range(value.record_start,records.size()):
  if eligible(records[i].result) and not state.hosted.has(records[i].id):
   state.pending = records[i].id
   break
 return state
static func chapter(state: Dictionary) -> Dictionary:
 if not state.active:
  return {"title":"A job with the Owls","voice":"Mara Vale, general manager: We have 48 loyal supporters, tired tools and just 120 seats. Help this little minor-league club find its feet.","goal":"Take the groundskeeper job. Your existing credits and purchased tools carry over; unupgraded tools become the starter kit."}
 if state.games == 0:
  return {"title":"Chapter 1 · Keep the gates open","voice":"Mara: The mower is borrowed, the hose is worn, and the town is waiting. You handle priority prep; volunteers finish the routine passes before we open.","goal":"Complete home-game prep, then host Opening Day. Choose how to reinvest the wages and gate money."}
 if "bleachers" not in state.buildings:
  return {"title":"Chapter 2 · A reason to come back","voice":"Mara: People are talking about the field again. Better tools save time, but those little bleachers will not hold a growing crowd forever.","goal":"Grow to 90 supporters and save 600 cr for community bleachers. Side contracts can help fund the club."}
 if "snack_shack" not in state.buildings:
  return {"title":"Chapter 3 · Make it a night out","voice":"Mara: We made room for the families. Now let's give them somewhere to buy supper and spend the evening together.","goal":"Build the 450 cr snack shack. Every attendee then brings in more income and word of mouth."}
 if "grandstand" not in state.buildings:
  return {"title":"Chapter 4 · A park to be proud of","voice":"Mara: The Owls finally feel like the town's team. Keep the field sharp and let's put a roof over those supporters.","goal":"Reach 200 supporters and invest 1,400 cr in the covered grandstand: 480 seats and better ticket income."}
 return {"title":"Chapter 5 · The town's club","voice":"Mara: Look what we built from an old mower and a few loyal families. Now let's fill this place.","goal":"Grow toward 480 supporters, keep hosting home games, and finish improving your tools. The club keeps earning after this chapter."}
