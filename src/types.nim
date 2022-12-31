import std/math

type Vec*[L:static[uint], T] = array[L, T]

type Vec2i* = Vec[2, int]
type Vec3f* = Vec[3, float]
type Vec2f* = Vec[2, float]

proc cross*(a, b: Vec3f): Vec3f =
  let a1 = a[0]
  let a2 = a[1]
  let a3 = a[2]

  let b1 = b[0]
  let b2 = b[1]
  let b3 = b[2]

  let s1 = a2 * b3 - a3 * b2
  let s2 = a3 * b1 - a1 * b3
  let s3 = a1 * b2 - a2 * b1

  return [s1, s2, s3]

proc len*(a: Vec3f): float =
  return sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2])

proc `/`*(a: Vec3f, s: float): Vec3f =
  return [a[0] / s, a[1] / s, a[2] / s]

proc normalised*(a: Vec3f): Vec3f =
  return a / len(a)

proc dot*(a, b: Vec3f): float =
  return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]

proc `+`*(a, b: Vec3f): Vec3f =
  return [a[0] + b[0], a[1] + b[1], a[2] + b[2]]

proc `-`*(a: Vec3f): Vec3f =
  return [-a[0], -a[1], -a[2]]

proc `-`*(a, b: Vec3f): Vec3f =
  return a + (-b)
