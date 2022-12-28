import pam

proc hline(x0, y0, x1: int, image: var Image, color: Color): void =
  # simple horizontal line from (x0, y0) to (x1, y0).
  let nx0 = (if x0 < x1: x0 else: x1)
  let nx1 = (if x0 < x1: x1 else: x0)

  for x in countup(x0, x1):
    set_pixel(image, x, y0, color)

proc vline(x0, y0, y1: int, image: var Image, color: Color): void =
  # simple vertical line from (x0, y0) to (x0, y1).
  let ny0 = (if y0 < y1: y0 else: y1)
  let ny1 = (if y0 < y1: y1 else: y0)
  for y in countup(ny0, ny1):
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