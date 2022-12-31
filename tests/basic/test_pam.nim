import ../../src/pam
import ../../src/types

# nim 0-init's all storage, so now we have a bunch of 0s
const width = 128
const height = 64
var im: Image[width, height]

# origin at bottom left is red
pam.set_pixel(im, 0, 0, [255u8, 0, 0, 255])

# opposing corner is green
pam.set_pixel(im, width-1, height-1, [0u8, 255, 0, 255])

# centre is blue
pam.set_pixel(im, width div 2, height div 2, [0u8, 0, 255, 255])

# to view the image: convert /tmp/test.pam /tmp/test.png && open /tmp/test.png
pam.write_image(im, "/tmp/test.pam")

let texture = load_texture("data/african_head.pam")
assert len(texture) == 1024
assert len(texture[0]) == 1024
assert texture[0][0] == [0x58u8, 0x45, 0x37, 255]

echo texture[^1][^1]
assert texture[^1][^1] == [0x63u8, 0x4f, 0x46, 255]
