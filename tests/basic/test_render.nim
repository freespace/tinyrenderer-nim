import ../../src/render
import ../../src/types

const a: Vec2i = [0, 0]
const b: Vec2i = [0, 10]
const c: Vec2i = [10, 0]

assert is_inside2d(a, a, b, c)
assert is_inside2d(b, a, b, c)
assert is_inside2d(c, a, b, c)
assert is_inside2d(Vec2i([5, 5]), a, b, c)
assert is_inside2d(Vec2i([10, 10]), a, b, c) == false
assert is_inside2d(Vec2i([-1, -1]), a, b, c) == false


