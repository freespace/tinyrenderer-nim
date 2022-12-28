import std/strformat
import ../../src/obj_loader

let model = load_model("data/african_head.obj")

echo(&"Loaded {len(model.v)} v")
echo(&"Loaded {len(model.vt)} vt")
echo(&"Loaded {len(model.faces)} f")

assert len(model.v) == 1258
assert len(model.vt) == 1339
assert len(model.faces) == 2492

assert model.v[0] == [-0.000581696, -0.734665, -0.623267]
assert model.vt[0] == [0.532, 0.923]
assert model.faces[0].v_idxes == [24, 25, 26]
assert model.faces[0].vt_idxes == [1, 2, 3]

echo("All tests pass")
