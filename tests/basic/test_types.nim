import ../../src/types

let a: Vec3f = [100.0, 0, 0]
assert len(a) == 100
assert len(a.normalised()) == 1

let b: Vec3f = [3.0, 4, 0]
assert len(b) == 5
assert len(b.normalised()) == 1

let c: Vec3f = [0.0, -3, -4]
assert len(b) == 5
assert len(b.normalised()) == 1

let d: Vec3f = [1.0, 3, -5]
let e: Vec3f = [4.0, -2, -1]
assert d.dot(e) == 3
assert d.dot(d) == len(d) * len(d)

assert a - b == [97.0, -4, 0]
