extends SceneTree
var failures := 0
func check(condition: bool,message: String) -> void:
 if condition:
  print("PASS: ",message)
 else:
  push_error(message)
  failures += 1
func _initialize() -> void:
 call_deferred("run")
func world(point: Vector2) -> Vector3:
 return Vector3(point.x,0,point.y)
func run() -> void:
 var chalk := ChalkSystem.new()
 root.add_child(chalk)
 check(chalk.percentage() == 0,"guides begin with zero chalk coverage")
 check(chalk.covered.size() == chalk.sections_per_line*2,"two independent foul lines are tracked")
 check(chalk.valid_count < chalk.covered.size(),"base pads are excluded from target totals")
 check(chalk.is_protected(Vector2(19.396,-19.396)) and chalk.is_protected(Vector2.ZERO),"bases and plate are protected from chalk")
 check(chalk.section_center(0,0).x < 0 and chalk.section_center(1,0).x > 0,"left and right sections map to their field sides")
 chalk.paint_segment(Vector3(0,0,-60),Vector3(0,0,-65))
 check(chalk.covered_count == 0,"off-guide strokes earn no line credit")
 check(not chalk.pending.is_empty(),"off-guide chalk is still drawn at its actual position")
 var strokes := chalk.pending.size()
 chalk.paint_segment(Vector3(0,0,-60),Vector3(0,0,-60))
 check(chalk.pending.size() == strokes,"stationary nozzle makes no stroke")
 var right := chalk.line_direction(1)
 chalk.paint_segment(world(right*5),world(right*15))
 check(chalk.covered_count > 30,"diagonal continuous stroke covers target sections")
 check(chalk.line_counts[0] == 0 and chalk.line_counts[1] > 0,"right stroke does not credit left line")
 var count := chalk.covered_count
 chalk.paint_segment(world(right*5),world(right*15))
 check(chalk.covered_count == count,"overlapping chalk passes count once")
 var across := Vector2(-right.y,right.x)*0.4
 chalk.paint_segment(world(right*20+across),world(right*30+across))
 check(chalk.covered_count == count,"parallel off-guide stroke cannot claim nearby sections")
 chalk.paint_segment(world(right*110),world(right*120))
 check(chalk.covered_count == count,"stroke beyond fence target earns no credit")
 chalk.paint_segment(world(right*20),world(right*15))
 check(chalk.covered_count > count,"stroke geometry works in either travel heading")
 check(chalk.distance_to_guide(world(right*10)) < 0.001,"on-guide distance is zero")
 check(chalk.distance_to_guide(world(right*10+across)) > 0.35,"guide distance detects lateral error")
 var left := chalk.line_direction(0)
 chalk.paint_segment(world(left*chalk.line_start),world(left*chalk.line_end))
 check(is_equal_approx(chalk.line_percentage(0),100.0),"entire left line can be completed")
 check(chalk.percentage() < 100,"one complete line is not both lines")
 chalk.paint_segment(world(right*chalk.line_start),world(right*chalk.line_end))
 check(is_equal_approx(chalk.percentage(),100.0),"both complete lines give exactly 100 percent")
 count = chalk.covered_count
 chalk.paint_segment(world(right*chalk.line_end),world(right*chalk.line_start))
 check(chalk.covered_count == count and chalk.percentage() == 100,"completed coverage cannot exceed 100 percent")
 chalk.flush_visuals()
 check(chalk.pending.is_empty() and chalk.get_child_count() > 1,"queued strokes produce persistent mesh batches")
 check(chalk.get_child_count() < 80,"chalk batches avoid a node per target section or paint sample")
 check(chalk.covered_count == count,"render batching preserves coverage state")
 print("Chalk failures: ",failures)
 quit(1 if failures else 0)
