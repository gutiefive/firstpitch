class_name ParkGeometry
extends RefCounted
static var material_cache: Dictionary = {}

static func material(color: Color) -> StandardMaterial3D:
 if material_cache.has(color):
  return material_cache[color]
 var m := StandardMaterial3D.new()
 m.albedo_color = color.srgb_to_linear()
 m.roughness = 0.85
 material_cache[color] = m
 return m

static func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, collision: bool = false) -> MeshInstance3D:
 var node := MeshInstance3D.new()
 var mesh := BoxMesh.new()
 mesh.size = size
 node.mesh = mesh
 node.material_override = surface_material(color)
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
 var surface_material := material(color).duplicate() as StandardMaterial3D
 surface_material.cull_mode = BaseMaterial3D.CULL_DISABLED
 node.material_override = surface_material
 parent.add_child(node)
 return node

static func label(parent: Node3D, text: String, pos: Vector3, size: int = 64) -> Label3D:
 var node := Label3D.new()
 node.text = text
 node.position = pos
 node.font_size = size
 node.outline_size = 0
 node.pixel_size = 0.02
 parent.add_child(node)
 return node

static func sphere(parent: Node3D, pos: Vector3, scale_size: Vector3, color: Color) -> MeshInstance3D:
 var node := MeshInstance3D.new()
 var mesh := SphereMesh.new()
 mesh.radius = 0.5
 mesh.height = 1
 mesh.radial_segments = 24
 mesh.rings = 12
 node.mesh = mesh
 node.material_override = material(color)
 node.position = pos
 node.scale = scale_size
 parent.add_child(node)
 return node

static func beam(parent: Node3D, from: Vector3, to: Vector3, width: float, color: Color) -> MeshInstance3D:
 var node := box(parent,(from+to)*0.5,Vector3(width,from.distance_to(to),width),color)
 var direction := (to-from).normalized()
 node.quaternion = Quaternion(Vector3.UP,direction)
 return node

static func ring(parent: Node3D, pos: Vector3, inner: float, outer: float, color: Color) -> MeshInstance3D:
 var node := MeshInstance3D.new()
 var mesh := TorusMesh.new()
 mesh.inner_radius = inner
 mesh.outer_radius = outer
 mesh.rings = 20
 mesh.ring_segments = 8
 node.mesh = mesh
 node.material_override = material(color)
 node.position = pos
 parent.add_child(node)
 return node

static func box_instances(parent: Node3D,positions: PackedVector3Array,size: Vector3,color: Color,title: String) -> MultiMeshInstance3D:
 var mesh := BoxMesh.new()
 mesh.size = size
 mesh.material = material(color)
 var batch := MultiMesh.new()
 batch.transform_format = MultiMesh.TRANSFORM_3D
 batch.mesh = mesh
 batch.instance_count = positions.size()
 for index in range(positions.size()):
  batch.set_instance_transform(index,Transform3D(Basis.IDENTITY,positions[index]))
 var node := MultiMeshInstance3D.new()
 node.name = title
 node.multimesh = batch
 parent.add_child(node)
 return node

static var bevel_cache: Dictionary = {}
static var canopy_cache: Dictionary = {}
static func mesh_face(surface: SurfaceTool,points: Array,normal: Vector3) -> void:
 for i in range(1,points.size()-1):
  var a: Vector3 = points[0]
  var b: Vector3 = points[i]
  var c: Vector3 = points[i+1]
  if (b-a).cross(c-a).dot(normal) > 0:
   var swap := b
   b = c
   c = swap
  for point in [a,b,c]:
   surface.set_normal(normal)
   surface.add_vertex(point)
static func bevel_mesh(size: Vector3) -> ArrayMesh:
 if bevel_cache.has(size):
  return bevel_cache[size]
 var h := size*0.5
 var radius := minf(minf(size.x,size.y),size.z)*0.16
 radius = minf(radius,0.075)
 var inner := h-Vector3.ONE*radius
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for axis in range(3):
  var u := (axis+1)%3
  var v := (axis+2)%3
  for side in [-1,1]:
   var normal := Vector3.ZERO
   normal[axis] = side
   var points := []
   for pair in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
    var p := normal*h[axis]
    p[u] = pair.x*inner[u]
    p[v] = pair.y*inner[v]
    points.append(p)
   mesh_face(surface,points,normal)
  for su in [-1,1]:
   for sv in [-1,1]:
    var points := []
    for pair in [Vector2(-1,0),Vector2(1,0),Vector2(1,1),Vector2(-1,1)]:
     var p := Vector3.ZERO
     p[axis] = pair.x*inner[axis]
     p[u] = su*(h[u] if pair.y == 0 else inner[u])
     p[v] = sv*(inner[v] if pair.y == 0 else h[v])
     points.append(p)
    var normal := Vector3.ZERO
    normal[u] = su
    normal[v] = sv
    mesh_face(surface,points,normal.normalized())
 for x in [-1,1]:
  for y in [-1,1]:
   for z in [-1,1]:
    var normal := Vector3(x,y,z)
    var points := []
    for axis in range(3):
     var p := inner*normal
     p[axis] = h[axis]*normal[axis]
     points.append(p)
    mesh_face(surface,points,normal.normalized())
 var mesh := surface.commit()
 bevel_cache[size] = mesh
 return mesh
static func soft_box(parent: Node3D,pos: Vector3,size: Vector3,color: Color,collision: bool = false) -> MeshInstance3D:
 var node := box(parent,pos,size,color,collision)
 node.mesh = bevel_mesh(size)
 node.material_override = surface_material(color)
 return node
static func capsule(parent: Node3D,pos: Vector3,radius: float,height: float,color: Color) -> MeshInstance3D:
 var node := MeshInstance3D.new()
 var mesh := CapsuleMesh.new()
 mesh.radius = radius
 mesh.height = maxf(height,radius*2)
 mesh.radial_segments = 20
 mesh.rings = 8
 node.mesh = mesh
 node.material_override = surface_material(color,3)
 node.position = pos
 parent.add_child(node)
 return node
static func canopy(parent: Node3D,pos: Vector3,size: Vector3,color: Color,variant: int) -> MeshInstance3D:
 var key := posmod(variant,5)
 if not canopy_cache.has(key):
  var surface := SurfaceTool.new()
  surface.begin(Mesh.PRIMITIVE_TRIANGLES)
  for row in range(16):
   for column in range(24):
    var vertices := []
    for pair in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
     var theta: float = PI*(row+pair.y)/16
     var phi: float = TAU*(column+pair.x)/24
     var direction := Vector3(sin(theta)*cos(phi),cos(theta),sin(theta)*sin(phi))
     var distortion := 1+0.055*sin(direction.x*7+key)*sin(direction.z*6-direction.y*5)+0.035*cos(direction.z*9+key*2+direction.y*4)
     vertices.append(direction*0.5*distortion)
    # Shared smooth normals, with deterministic lobes rather than sphere clusters.
    for i in [0,2,1,0,3,2]:
     var p: Vector3 = vertices[i]
     surface.set_normal(p.normalized())
     surface.add_vertex(p)
  canopy_cache[key] = surface.commit()
 var node := MeshInstance3D.new()
 node.mesh = canopy_cache[key]
 var leaf_key := "leaf"+str(color)
 if not surface_cache.has(leaf_key):
  var leaves := ShaderMaterial.new()
  leaves.shader = preload("res://shaders/foliage.gdshader")
  leaves.set_shader_parameter("leaf_color",color.srgb_to_linear())
  surface_cache[leaf_key] = leaves
 node.material_override = surface_cache[leaf_key]
 node.position = pos
 node.scale = size
 parent.add_child(node)
 return node

static var surface_cache: Dictionary = {}
static func surface_material(color: Color,kind: int = 0) -> ShaderMaterial:
 var key := str([color,kind])
 if surface_cache.has(key):
  return surface_cache[key]
 var result := ShaderMaterial.new()
 result.shader = preload("res://shaders/park_surface.gdshader")
 result.set_shader_parameter("base_color",color.srgb_to_linear())
 result.set_shader_parameter("surface_kind",kind)
 surface_cache[key] = result
 return result

static func timber(parent: Node3D,pos: Vector3,size: Vector3,color: Color,collision: bool = false) -> MeshInstance3D:
 var node := soft_box(parent,pos,size,color,collision)
 node.material_override = surface_material(color,1)
 return node
static func cladding(root: Node3D,width: float,height: float,depth: float,color: Color) -> void:
 var plinth := soft_box(root,Vector3(0,0.15,0),Vector3(width+0.10,0.30,depth+0.10),Color("858176"))
 plinth.material_override = surface_material(Color("858176"),2)
 for row in range(1,int(height/0.24)):
  var y := row*0.24
  box(root,Vector3(0,y,depth*0.5+0.016),Vector3(width,0.018,0.025),color)
  for side in [-1,1]:
   box(root,Vector3(side*(width*0.5+0.016),y,0),Vector3(0.025,0.018,depth),color)

static func tailored_body(parent: Node3D,pos: Vector3,color: Color) -> MeshInstance3D:
 var profile := [Vector2(-0.32,0.185),Vector2(-0.25,0.19),Vector2(-0.08,0.205),Vector2(0.12,0.235),Vector2(0.23,0.21),Vector2(0.29,0.13),Vector2(0.32,0.075)]
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for row in range(profile.size()-1):
  for column in range(24):
   var vertices := []
   var normals := []
   var slope: float = (profile[row+1].y-profile[row].y)/(profile[row+1].x-profile[row].x)
   for pair in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
    var ring: Vector2 = profile[row+int(pair.y)]
    var angle: float = TAU*(column+pair.x)/24
    vertices.append(Vector3(cos(angle)*ring.y,ring.x,sin(angle)*ring.y*0.72))
    normals.append(Vector3(cos(angle),-slope,sin(angle)/0.72).normalized())
   for i in [0,1,2,0,2,3]:
    surface.set_normal(normals[i])
    surface.add_vertex(vertices[i])
 var node := MeshInstance3D.new()
 node.mesh = surface.commit()
 node.material_override = surface_material(color,3)
 node.position = pos
 parent.add_child(node)
 return node

static var seat_cache: Dictionary = {}
static func seat_instances(parent: Node3D,positions: PackedVector3Array,size: Vector3,color: Color,title: String,back: bool = false) -> MultiMeshInstance3D:
 var node := box_instances(parent,positions,size,color,title)
 if not back:
  node.multimesh.mesh = bevel_mesh(size)
 else:
  if not seat_cache.has(size):
   var surface := SurfaceTool.new()
   surface.begin(Mesh.PRIMITIVE_TRIANGLES)
   for side in [-1,1]:
    for row in range(4):
     for column in range(10):
      var points := []
      for pair in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
       var u: float = (column+pair.x)/10-0.5
       var v: float = (row+pair.y)/4-0.5
       var taper := 1-0.13*smoothstep(0.2,0.5,v)
       points.append(Vector3(u*size.x*taper,v*size.y,size.z*side*0.5+0.035*(1-4*u*u)+v*0.10))
      mesh_face(surface,points,Vector3(0,-0.23,side).normalized())
   # Caps close the molded shell around its perimeter.
   for edge in range(4):
    var points := []
    for pair in [Vector2(0,-1),Vector2(1,-1),Vector2(1,1),Vector2(0,1)]:
     var u: float = pair.x-0.5 if edge < 2 else (-0.5 if edge == 2 else 0.5)
     var v: float = (-0.5 if edge == 0 else 0.5) if edge < 2 else pair.x-0.5
     var taper := 1-0.13*smoothstep(0.2,0.5,v)
     points.append(Vector3(u*size.x*taper,v*size.y,size.z*pair.y*0.5+0.035*(1-4*u*u)+v*0.10))
    mesh_face(surface,points,Vector3(0,-1 if edge == 0 else 1,0) if edge < 2 else Vector3(-1 if edge == 2 else 1,0,0))
   seat_cache[size] = surface.commit()
  node.multimesh.mesh = seat_cache[size]
 node.material_override = surface_material(color)
 return node
static func tube(parent: Node3D,from: Vector3,to: Vector3,radius: float,color: Color) -> MeshInstance3D:
 var node := cylinder(parent,(from+to)*0.5,radius,from.distance_to(to),color)
 node.quaternion = Quaternion(Vector3.UP,(to-from).normalized())
 return node
