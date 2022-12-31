import std/strutils
import std/strscans
import std/strformat

import types

type ParsingDefect = object of Defect

# geometry vertex
type V* = Vec[3, float]

# texture vertex
type VT* = Vec[2, float]

type Face* = ref object
  # these are indices into the containing model's
  # v and vt sequences respectively
  v_idxes*: seq[int]
  vt_idxes*: seq[int]

type Model* = ref object
  filename*: string
  faces*: seq[Face]
  v*: seq[V]
  vt*: seq[VT]

proc load_model*(obj_path: string): Model =
  let fh = open(obj_path)

  var linebuf: string
  var model = new(Model)

  while readLine(fh, linebuf):
    if linebuf.startsWith("v "):
      # this line will look like
      #   v 0.123 0.234 0.345
      # we only care about the first 3 values even if a 4th may be present
      var x, y, z: float
      if scanf(linebuf, "v $s$f $f $f", x, y, z):
        model.v.add([x, y, z])
      else:
        raise newException(ParsingDefect, &"Failed to parse {linebuf}")
    elif linebuf.startsWith("vt "):
      # this line will look like
      #   vt 0.500 1
      # we only care about the first 2 values even if a 3rd may be present
      var u, v: float
      if scanf(linebuf, "vt $s$f $f", u, v):
        model.vt.add([u, v])
      else:
        raise newException(ParsingDefect, &"Failed to parse {linebuf}")
    elif linebuf.startsWith("f "):
      var face = new(Face)
      model.faces.add(face)

      # this line will look like
      #   f v0[/vt0] v1[/vt1] v2[/vt2] [vn[/vtn]...]
      # there will be at _least_ 3 vertices to form a triangle. We need all
      # of it. vts are optional
      for item in linebuf[1..^1].splitWhitespace():
        var vidx, vtidx: int
        if scanf(item, "$i/$i", vidx, vtidx):
          face.v_idxes.add(vidx)
          face.vt_idxes.add(vtidx)
        elif scanf(item, "$i", vidx):
          face.v_idxes.add(vidx)
        else:
            raise newException(ParsingDefect, &"Failed to parse {linebuf}")

  return model

