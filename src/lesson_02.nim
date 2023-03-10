import pam
import render
import types
import obj_loader

const red: Color = [255u8, 0, 0, 255]
const white: Color = [255u8, 255, 255, 255]
const green: Color = [0u8, 255, 0, 255]

const t0: array[3, Vec2i] = [[10, 70], [50, 160], [70, 80]]
const t1: array[3, Vec2i] = [[180, 50], [150, 1], [70, 180]]
const t2: array[3, Vec2i] = [[180, 150], [120, 160], [130, 180]]

var image: Image[256, 256]

image.triangle(t0[0], t0[1], t0[2], red)
image.triangle(t1[0], t1[1], t1[2], white)
image.triangle(t2[0], t2[1], t2[2], green)

write_image(image, "outputs/lesson_02a.pam")

var im2: Image[1024, 1024]
let model = load_model("data/african_head.obj")

proc to_screenspace(p: Vec3f): Vec2i =
  # the model is centered around (0, 0) with coordinates between (-1, 1).
  # By adding 1 we shift the origin to (1, 1) which means the minimum coordinate
  # is (0, 0). Finally we scale by half the width and height so  0->0 and 2->width/height
  let sx = int((p[0] + 1) * 512)
  let sy = int((p[1] + 1) * 512)

  return [sx, sy]

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
    im2.triangle(sa, sb, sc, [c, c, c, 255])

im2.write("outputs/lesson_02b.pam")
