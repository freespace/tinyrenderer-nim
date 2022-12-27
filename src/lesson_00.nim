import pam

const red: pam.Color = [255u8, 0, 0, 255]

var im: pam.Image[100, 100]

pam.set_pixel(im, 52, 41, red)
pam.write_image(im, "lesson_00.pam")


