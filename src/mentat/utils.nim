import sequtils

func normalize*(data: seq[float], factor: float) : seq[float] =
    return map(data, proc(x: float): float = x / factor)

func cusum*(data: seq[float]): seq[float] =
    let N = len(data)
    result = newSeqWith(N, 0.0)
    for i in (0..<N):
        result[i] = foldr(data[0..i], a + b)
    return result