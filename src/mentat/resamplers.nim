import utils
import sequtils
import random

proc multinomial*(weights: seq[float]) : seq[int] =
    let N = len(weights)
    let nw = normalize(weights, foldr(weights, a + b))
    let Q = cusum(nw)

    var indices = newSeqWith(N, 0)

    var i = 0

    while i < N:
        let sample = rand(1.0)
        var j = 0
        while Q[j] < sample:
            j += 1
        indices[i] = j
        i += 1

    return indices