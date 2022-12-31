import pam
import types

proc hline(x0, y0, x1: int, image: var Image, color: Color): void =
  # simple horizontal line from (x0, y0) to (x1, y0).
  let minx = min(x0, x1)
  let maxx = max(x0, x1)

  for x in countup(minx, maxx):
    set_pixel(image, x, y0, color)

proc vline(x0, y0, y1: int, image: var Image, color: Color): void =
  # simple vertical line from (x0, y0) to (x0, y1).
  let miny = min(y0, y1)
  let maxy = max(y0, y1)
  for y in countup(miny, maxy):
    set_pixel(image, x0, y, color)

proc line*(x0, y0, x1, y1: int, image: var Image, color: Color): void =
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
    vline(x0, y0, y1, image, color)
    return

  if y1 == y0:
    hline(x0, y0, x1, image, color)
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

proc line*(a, b,: Vec2i, image: var Image, color: Color): void =
  line(a[0], a[1], b[0], b[1], image, color)

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
  let bcoords = barycentric2d(p, a, b, c)

  for c in bcoords:
    if c < 0:
      return false

  return true

proc triangle*(a, b, c: Vec2i, image: var Image, color: Color): void =
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
