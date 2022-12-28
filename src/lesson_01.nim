import pam
import render
import obj_loader

const red: Color = [255u8, 0, 0, 255]
const white: Color = [255u8, 255, 255, 255]
const green: Color = [0u8, 255, 0, 255]
const blue: Color = [0u8, 0, 255, 255]

var im: Image[100, 100]

line(13, 20, 80, 40, im, white);
line(20, 13, 40, 80, im, red);
line(80, 40, 13, 20, im, red);
line(0, 0, 1, 50, im, green)
line(0, 0, 50, 1, im, green)
line(40, 40, 40, 60, im, blue)
line(40, 40, 60, 40, im, blue)

write_image(im, "lesson_01a.pam")

let model = load_model("data/african_head.obj")
var im2: Image[1024, 1024]

proc screenspace_line(x0, y0, x1, y1: float, color: Color): void =
  # the model is centered around (0, 0) with coordinates between (-1, 1).
  # By adding 1 we shift the origin to (1, 1) which means the minimum coordinate
  # is (0, 0). Finally we scale by half the width and height so  0->0 and 2->width/height
  let sx0 = int((x0 + 1) * 512)
  let sy0 = int((y0 + 1) * 512)
  let sx1 = int((x1 + 1) * 512)
  let sy1 = int((y1 + 1) * 512)

  line(sx0, sy0, sx1, sy1, im2, color)

for face in model.faces:
  # assume all faces are triangles. Recall also that the obj file format uses
  # 1-indexing
  let a = model.v[face.v_idxes[0]-1]
  let b = model.v[face.v_idxes[1]-1]
  let c = model.v[face.v_idxes[2]-1]

  # not that we drop the z coordinate for now
  screenspace_line(a[0], a[1], b[0], b[1], green)
  screenspace_line(a[0], a[1], c[0], c[1], green)
  screenspace_line(b[0], b[1], c[0], c[1], green)

write_image(im2, "lesson_01b.pam")
