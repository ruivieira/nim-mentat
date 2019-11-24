import matplotnim
import mentat/resamplers
import mentat/utils
import random
import sequtils

let s = newSeqWith(100, rand(1.0))

echo s

let i = multinomial(s)

echo i

let resampled = cusum(map(i, proc(x: int): float = s[x]))

let figure = newFigure()
let x = toSeq(0..<100)
let sp = newLinePlot(x, resampled)
figure.add sp
figure.save("examples/ex_resamplers.png")

