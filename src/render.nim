import pam
import types

proc hline(image: var Image, x0, y0, x1: int, color: Color): void =
  # simple horizontal line from (x0, y0) to (x1, y0).
  let minx = min(x0, x1)
  let maxx = max(x0, x1)

  for x in countup(minx, maxx):
    image.set_pixel(x, y0, color)

proc vline(image: var Image, x0, y0, y1: int,color: Color): void =
  # simple vertical line from (x0, y0) to (x0, y1).
  let miny = min(y0, y1)
  let maxy = max(y0, y1)
  for y in countup(miny, maxy):
    image.set_pixel(x0, y, color)

proc line*(image: var Image, x0, y0, x1, y1: int, color: Color): void =
  # We want to avoid floating point ops, and we shouldn't need it, because we know
  # at least we need pixel coordinates to go from x0 and x1 in steps of 1, and similarly
  # from y0 to y1 in steps of 1.
  #
  # Some considerations:
  #
  #   - if we use x = x0 -> x1 as the driver, we may need to generate more than 1 y coordinate
  #     per x-step due to gradient. The same is true if we step along y
  #
  #   - we want consistent drawing direction so the maths is always increasing

  if x1 == x0:
    image.vline(x0, y0, y1, color)
    return

  if y1 == y0:
    image.hline(x0, y0, x1, color)
    return

  let dx = x1 - x0

  var nx0, ny0, nx1, ny1: int
  if dx < 0:
    # make sure we are always going left to right
    nx0 = x1
    nx1 = x0
    ny0 = y1
    ny1 = y0
  else:
    nx0 = x0
    nx1 = x1
    ny0 = y0
    ny1 = y1

  # for each x-step, we need to move an equivalent y step, which is 1 if the line is 45 degrees,
  # <1 if less, and >1 if more. Note that we can avoid the floating point here because
  #
  #    dydx = dy / dx
  #    ...
  #    error += dydx
  #    if error > 0.5:
  #      ...
  #      error -= 1
  #
  # can be rewritten first by multiplying everything by dx:
  #
  #    dy = dy
  #    ...
  #    error += dy
  #    if error > 0.5 * dx:
  #      ...
  #      error -= dx
  #
  # and finally if we multiply everything by 2 as well
  #
  #    dy2 = 2 * dy
  #    ...
  #    error += dy2
  #    if error > dx:
  #      ...
  #      error -= 2 * dx
  #
  # note that error += derror doesn't change b/c the scaling is implicit, we only need to balance
  # the if condition

  let dy2 = (if ny0 < ny1: ny1 - ny0 else: ny0 - ny1) * 2
  let ndx = nx1 - nx0

  # now we step along x, and for each step, accumulate the y error. When the y error is over 1
  # increase where we will draw the next y pixel
  var y = ny0
  var error: int = 0
  let maxy = high(image)

  for x in countup(nx0, nx1):
    set_pixel(image, x, y, color)

    error += dy2
    while error > ndx:
      if ny0 > ny1:
        y = (if y > 1: y - 1 else: 0)
        # this is needed so prevent us drawing past our end point
        # due to error buildup which can happen for line which are
        # *effectively* vertical, but technically aren't
        if y < ny1:
          break
      else:
        y = (if y < maxy: y + 1 else: maxy)
        if y > ny1:
          break

      set_pixel(image, x, y, color)

      error -= 2 * ndx

proc line*(image: var Image, a, b,: Vec2i, color: Color): void =
  image.line(a[0], a[1], b[0], b[1], color)

proc barycentric2d(p: Vec2i, a, b, c: Vec2i): Vec3f =
  # based on
  # https://en.wikipedia.org/wiki/Barycentric_coordinate_system#Barycentric_coordinates_on_triangles
  let x = p[0]
  let y = p[1]

  let x1 = a[0]
  let y1 = a[1]
  let x2 = b[0]
  let y2 = b[1]
  let x3 = c[0]
  let y3 = c[1]

  let detT = (y2 - y3) * (x1 - x3) + (x3 - x2) * (y1 - y3)

  let lambda1 = ((y2 - y3) * (x - x3) + (x3 - x2) * (y - y3)) / detT
  let lambda2 = ((y3 - y1) * (x - x3) + (x1 - x3) * (y - y3)) / detT
  let lambda3 = 1 - lambda1 - lambda2

  return [lambda1, lambda2, lambda3]

proc is_inside2d*(p, a, b, c: Vec2i): bool =
  let bcoords: array[3, float] = barycentric2d(p, a, b, c)

  for idx in 0..high(bcoords):
    if bcoords[idx] < 0:
      return false

  return true

proc triangle*(image: var Image, a, b, c: Vec3f, zbuffer: var ZBuffer, color: Color): void =
  # a, b and c should be in screen coordinates

  let a2d = a.asVec2i()
  let b2d = b.asVec2i()
  let c2d = c.asVec2i()


  # compute the bounding box, sweep each pixel in the bounding box and  and use is_inside2d
  # to determine if the pixel is inside or out. If inside, fill it with color, otherwise
  # do nothing
  let minx = min(a2d[0], b2d[0]).min(c2d[0])
  let maxx = max(a2d[0], b2d[0]).max(c2d[0])

  let miny = min(a2d[1], b2d[1]).min(c2d[1])
  let maxy = max(a2d[1], b2d[1]).max(c2d[1])

  let did_draw: bool = false

  for x in minx..maxx:
    for y in miny..maxy:
      let p: Vec2i = [x, y]
      let bc_coords = barycentric2d(p, a2d, b2d, c2d)
      let is_inside: bool = bc_coords[0] >= 0 and bc_coords[1] >= 0 and bc_coords[2] >= 0
      if is_inside:

        # interpolate the z coordinate using the barycentric as weights
        let z = bc_coords[0] * a[2].float + bc_coords[1] * b[2].float + bc_coords[2] * c[2].float

        # if there is nothing "in front" of us, draw the pixel. This implies Z gets bigger
        # TOWARDS the user, i.e. -z is into the screen, positive z is out of the screen
        if zbuffer[y][x] < z:
          zbuffer[y][x] = z
          image.set_pixel(x, y, color)

proc triangle*(image: var Image, a, b, c: Vec2i, color: Color): void =
  # a, b and c should be in screen coordinates
  # explicitly draw the boundary b/c the is-inside function might behave funny around the
  # boundary due to floating point errors
  image.line(a, b, color)
  image.line(a, c, color)
  image.line(b, c, color)

  # compute the bounding box, sweep each pixel in the bounding box and  and use is_inside2d
  # to determine if the pixel is inside or out. If inside, fill it with color, otherwise
  # do nothing
  let minx = min(a[0], b[0]).min(c[0])
  let maxx = max(a[0], b[0]).max(c[0])

  let miny = min(a[1], b[1]).min(c[1])
  let maxy = max(a[1], b[1]).max(c[1])

  for x in minx..maxx:
    for y in miny..maxy:
      let p: Vec2i = [x, y]
      if is_inside2d(p, a, b, c):
        image.set_pixel(x, y, color)
