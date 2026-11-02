class_name ParkGeometry
extends RefCounted

static func material(color: Color) -> StandardMaterial3D:
 var m := StandardMaterial3D.new()
 m.albedo_color = color.srgb_to_linear()
 m.roughness = 0.85
 return m

static func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, collision: bool = false) -> MeshInstance3D:
 var node := MeshInstance3D.new()
 var mesh := BoxMesh.new()
 mesh.size = size
 node.mesh = mesh
 node.material_override = material(color)
 node.position = pos
 parent.add_child(node)
 if collision:
  var body := StaticBody3D.new()
  var shape := CollisionShape3D.new()
  var bounds := BoxShape3D.new()
  bounds.size = size
  shape.shape = bounds
  body.add_child(shape)
  node.add_child(body)
 return node

static func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
 var node := MeshInstance3D.new()
 var mesh := CylinderMesh.new()
 mesh.top_radius = radius
 mesh.bottom_radius = radius
 mesh.height = height
 mesh.radial_segments = 20
 node.mesh = mesh
 node.material_override = material(color)
 node.position = pos
 parent.add_child(node)
 return node

static func sector(parent: Node3D, inner: float, outer: float, y: float, color: Color) -> MeshInstance3D:
 var mesh := ImmediateMesh.new()
 mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in range(90):
  var a := deg_to_rad(-45.0 + i)
  var b := deg_to_rad(-44.0 + i)
  var p := Vector3(sin(a),0,-cos(a))
  var q := Vector3(sin(b),0,-cos(b))
  for v in [p*inner,q*outer,p*outer,p*inner,q*inner,q*outer]:
   mesh.surface_set_normal(Vector3.UP)
   mesh.surface_add_vertex(v + Vector3.UP*y)
 mesh.surface_end()
 var node := MeshInstance3D.new()
 node.mesh = mesh
 var surface_material := material(color)
 surface_material.cull_mode = BaseMaterial3D.CULL_DISABLED
 node.material_override = surface_material
 parent.add_child(node)
 return node

static func label(parent: Node3D, text: String, pos: Vector3, size: int = 64) -> Label3D:
 var node := Label3D.new()
 node.text = text
 node.position = pos
 node.font_size = size
 node.pixel_size = 0.02
 parent.add_child(node)
 return node
