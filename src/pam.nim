import std/strformat

# expected to be RGBA
type Pixel* = array[4, uint8]
type Color* = Pixel

# W, H: static[int] declares W and H to be integer type parameters which must be constant
# expressions. The latter is enforced via static[]. Note that the image is stored row-major
# so image[0] is the first row, i.e. indexing is (y, x) not (x, y). For this reason
# it is strongly suggested to use set_pixel() to set colours as it will translate the (x, y)
# into (col, row)
type Image*[W, H: static[uint]] = array[H, array[W, Pixel]]

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
