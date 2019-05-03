import matplotnim
import mentat/timeseries
import random
import sequtils

var data: seq[float] = newSeq[float](1000)

data[0] = 10.0

for i in 1..<1000:
    data[i] = data[i-1] + 1.0 - rand(2.0)


var avg: seq[float] = newSeq[float](1000)
avg[0] = data[0]
let ewma = newEWMA(data[0], 50)
for i in 1..<1000:
    avg[i] = ewma.update(data[i])

let figure = newFigure()
let x = toSeq(0..<1000)
let sp = newScatterPlot(x, data)
figure.add sp
let lp = newLinePlot(x, avg)
lp.colour = "red"
figure.add lp
figure.save("examples/ex_ewma.png")