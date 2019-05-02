import sequtils
import math

type SplineInterpolator* = ref object of RootObj
    X: seq[float]
    Y: seq[float]
    M: seq[float] 

func hermite(self: SplineInterpolator, i: int, h: float, t: float) : float =
    (self.Y[i] * (1.0 + 2.0 * t) + h * self.M[i] * t) * (1.0 - t) * (1.0 - t) + (self.Y[i + 1] * (3.0 - 2.0 * t) + h * self.M[i + 1] * (t - 1.0)) * t * t

func interpolate*(self: SplineInterpolator, x: float) : float =
    let n = len(self.X)
    if x <= self.X[0]:
        return self.Y[0]

    if x >= self.X[n-1]:
        return self.Y[n-1]

    var i = 0
    while x >= self.X[i+1]:
        i += 1
        if x==self.X[i]:
            return self.Y[i]

    let h = self.X[i+1] - self.X[i]
    let t = (x - self.X[i]) / h

    return self.hermite(i, h, t)

proc newSplineInterpolator*(x: seq[float], y: seq[float]): SplineInterpolator =
    assert(len(x)==len(y) and len(x) >= 2, "Inputs must have the same size")
    
    let n = len(x)
    var d = newSeqWith(n-1, 0.0)

    # calculate Ms
    var M = newSeqWith(n, 0.0)

    for i in 0..<(n-1):
        let h = x[i+1] - x[i]
        assert(h>0, "X must be monotonically increasing")
        d[i] = (y[i+1] - y[i]) / h

    M[0] = d[0]
    for i in 1..<(n-1):
        M[i] = (d[i-1] + d[i]) * 0.5
    M[n-1] = d[n-2]
    for i in 0..<(n-1):
        if d[i]==0:
            M[i] = 0.0
            M[i+1] = 0.0
        else:
            let a = M[i] / d[i]
            let b = M[i+1] / d[i]
            let h = hypot(a, b)
            if h > 3.0:
                let t = 3.0 / h
                M[i] = t * a * d[i]
                M[i+1] = t * b * d[i]
    SplineInterpolator(X: x, Y: y, M: M)

