import pam
import render
import types

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

write_image(image, "outputs/lesson_02.pam")
