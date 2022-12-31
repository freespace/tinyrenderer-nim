import pam
import render
import types
import obj_loader

var im: Image[1024, 1024]
var zbuffer: ZBuffer[1024, 1024]

im.init()
zbuffer.init()

let model = load_model("data/african_head.obj")

proc to_screenspace(p: Vec3f): Vec3f =
  # the model is centered around (0, 0) with coordinates between (-1, 1).
  # By adding 1 we shift the origin to (1, 1) which means the minimum coordinate
  # is (0, 0). Finally we scale by half the width and height so  0->0 and 2->width/height
  let sx = (p[0] + 1) * 511.5
  let sy = (p[1] + 1) * 511.5

  # leave z untouched
  return [sx, sy, p[2]]

# this is model space which is -1..1
let light_dir: Vec3f = [0.0, 0.0, -1]

for face in model.faces:
  # assume all faces are triangles. Recall also that the obj file format uses
  # 1-indexing
  let a = model.v[face.v_idxes[0]-1]
  let b = model.v[face.v_idxes[1]-1]
  let c = model.v[face.v_idxes[2]-1]

  let sa = to_screenspace(a)
  let sb = to_screenspace(b)
  let sc = to_screenspace(c)

  # compute triangle's normal by cross a-b and a-c
  let normal = (c-a).cross(b-c).normalised()
  let intensity = normal.dot(light_dir)
  if intensity > 0:
    let c = (intensity * 255).uint8
    im.triangle(sa, sb, sc, zbuffer, [c, c, c, 255])

im.write("outputs/lesson_03a.pam")
