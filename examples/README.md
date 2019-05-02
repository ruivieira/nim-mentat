# mentat examples

## Splines
<a name="splines"></a>

### Monotonic Cubic Spline interpolation

```nim
import matplotnim
import mentat/splines

let x = @[0.0, 1.0, 4.0, 8.0]
let y = @[1.1, 3.3, 7.9, 8.3]

let spline = newSplineInterpolator(x, y)

var x2 = newSeq[float](100)
var y2 = newSeq[float](100)

for p in 0..<100:
    x2[p] = float(p) / 10.0
    y2[p] = spline.interpolate(x2[p])

let figure = newFigure()
let points = newScatterPlot(x, y)
points.colour = "orange"
figure.add points
let line = newLinePlot(x2, y2)
figure.add line
figure.save("examples/spline_interpolation.png")
```

![](spline_interpolation.png)