import std/strformat
import pam
import render
import types
import obj_loader

const imwidth = 1024
const imheight = 1024
var im: Image[imwidth, imheight]
var zbuffer: ZBuffer[imwidth, imheight]

im.init()
zbuffer.init()

let model = load_model("data/spaceship.obj")
let texture = load_texture("data/spaceship-color-inv.pam")

# this is model space which is -1..1. This also needs to be normalised
# so the dot-product with normals is 0..1
let light_dir: Vec3f = normalised([-1.0, -1.0, -1])

proc to_screenspace(p: Vec3f): Vec3f =
  # the model is centered around (0, 0) with coordinates between (-1, 1).
  # By adding 1 we shift the origin to (1, 1) which means the minimum coordinate
  # is (0, 0). Finally we scale by half the width and height so  0->0 and 2->width/height
  let sx = (p[0]/model.max_v + 1) * imwidth / 2
  let sy = (p[1]/model.max_v + 1) * imheight / 2


  # leave z untouched
  return [sx, sy, p[2]]

for face in model.faces:
  # assume all faces are triangles. Recall also that the obj file format uses
  # 1-indexing
  let a = model.v[face.v_idxes[0]-1]
  let b = model.v[face.v_idxes[1]-1]
  let c = model.v[face.v_idxes[2]-1]

  # texture coordinates
  let ta = model.vt[face.vt_idxes[0]-1]
  let tb = model.vt[face.vt_idxes[1]-1]
  let tc = model.vt[face.vt_idxes[2]-1]

  let sa = to_screenspace(a)
  let sb = to_screenspace(b)
  let sc = to_screenspace(c)

  # compute triangle's normal
  let normal = (c-a).cross(b-a).normalised()

  # use of max here disables back-face culling but also lets us move the light source around
  # without faces disapearing
  let intensity = max(normal.dot(light_dir), 0.3)
  im.triangle(sa, sb, sc, zbuffer, ta, tb, tc, intensity, texture)

im.write("outputs/spaceship.pam")
