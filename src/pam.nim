import std/strformat
import std/strutils
import std/strscans

import types

type InvalidPAMHeaderDefect = object of Defect

# this has to come before so overloaded variants can find this underlying implementation
proc set_pixel*(image: var Image, x: uint16, y: uint16, pixel: Pixel): void =
  let px = min(high(image[0]).uint16, x)
  let py = min(high(image).uint16, y)
  image[py][px] = pixel

proc set_pixel*(image: var Image, x: int, y: int, pixel: Pixel): void =
  let xx = max(0, x).uint16
  let yy = max(0, y).uint16
  set_pixel(image, xx, yy, pixel)

proc write_image*(image: Image, output_path: string): void =
  let out_fh = io.open(output_path, FileMode.fmWrite)

  # write out the ascii header starting with magic that identifies this as a binary
  # PPM image
  io.write(out_fh, "P7\n")

  # ... then the image dimensions
  const width_str = &"WIDTH {len(image[0])}\n"
  const height_str = &"HEIGHT {len(image)}\n"

  io.write(out_fh, width_str)
  io.write(out_fh, height_str)

  # ... then the number of channels, always 4 for RGBA
  io.write(out_fh, "DEPTH 4\n")

  # ...  then the maximum value, which is 255 as we are using 1 byte per channel
  io.write(out_fh, "MAXVAL 255\n")

  # ... then the pixel type
  io.write(out_fh, "TUPLTYPE RGB_ALPHA\n")

  # ... and signal end of the header
  io.write(out_fh, "ENDHDR\n")

  # now write out the image, one pixel at a time. First the red value, then green and finally blue.
  # Note that we write bottom up, so the image is flipped with origin at bottom-left instead of
  # top-left
  for rdx in countdown(high(image), 0):
    for cdx in 0..high(image[0]):
      let pixel = image[rdx][cdx]
      if io.writeBytes(out_fh, pixel, 0, len(pixel)) != len(pixel):
        raise newException(IOError, "Fewer than expected number of bytes written")

  io.close(out_fh)

proc write*(image: Image, output_path: string): void =
  # Alias for write_image
  write_image(image, output_path)

proc load_texture*(input_path: string): Texture =
  let fh = io.open(input_path)
  defer: io.close(fh)

  let magic = io.readLine(fh)
  if magic != "P7":
    raise newException(InvalidPAMHeaderDefect, "File does not start with P7")

  var header_ended: bool = false
  var width, height, depth, maxval: int

  proc parse_int(field, target_name: string, out_var: var int): bool =
    var fname: string
    var tmp: int
    if field.scanf("$+ $i", fname, tmp):
      if fname == target_name:
        out_var = tmp
        return true

    return false

  while not header_ended:
    let field = io.readLine(fh)

    if field == "ENDHDR":
      header_ended = true
    elif field.startsWith("TUPLTYPE "):
      # we only handle RGB and RGBA, which we will infer from DEPTH
      discard
    else:
      var parsed = false
      parsed = parsed or field.parse_int("WIDTH", width)
      parsed = parsed or field.parse_int("HEIGHT", height)
      parsed = parsed or field.parse_int("DEPTH", depth)
      parsed = parsed or field.parse_int("MAXVAL", maxval)

      if not parsed:
        raise newException(InvalidPAMHeaderDefect, &"Unknown header field {field}")

  echo &"{width=}"
  echo &"{height=}"
  echo &"{depth=}"

  # 1200 b/c for either 3 or 4 bytes per pixel we also have a whole number of pixels
  # per buffer
  var buffer: array[1200, uint8]

  var end_reached = false

  var texture: Texture
  newSeq(texture, height)

  var current_row: seq[array[4, uint8]]
  newSeq(current_row, width)

  var pixel_idx = 0
  var row_idx = 0

  while not end_reached:
    let bytesread = io.readBytes(fh, buffer, 0, len(buffer))
    if bytesread < len(buffer):
      end_reached = true
      break

    for idx, val in buffer:
      current_row[pixel_idx][idx mod depth] = val

      # are we done with this pixel? This code triggers
      # after every $depth number of values, e.g. for depth=3
      # this triggers at idx = 2, i.e. after we have read 3 values
      if (idx + 1) mod depth == 0:
        # if yes, fill in the alpha value if needed
        if depth < 4:
          current_row[pixel_idx][3] = 255u8

        # move to the next pixel
        pixel_idx += 1

      if pixel_idx >= high(current_row):
        texture[row_idx] = current_row
        newSeq(current_row, width)
        pixel_idx = 0
        row_idx += 1

  return texture
