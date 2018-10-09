import science/Matrix
import science/Vector
import Math
import strutils
import random

proc batchALS*(R: Matrix, P: Matrix, Q: Matrix, rank: int, alpha: float = 0.0002, beta: float = 0.02): (Matrix, Matrix) =
    let Qt = Q.transpose()
    let nrows = R.nrows
    let ncols = R.ncols
    for i in 0..<nrows:
        for j in 0..<ncols:
            if R[i,j] > 0.0:
                let eij = R[i,j] - P.row(i).dot(Qt.col(j))
                for k in 0..<rank:
                    P[i,k] = P[i,k] + alpha * (2.0 * eij * Qt[k,j] - beta * P[i,k])
                    Qt[k,j] = Qt[k,j] + alpha * (2.0 * eij * P[i,k] - beta * Qt[k,j])
    var e = 0.0
    for i in 0..<nrows:
        for j in 0..<ncols:
            if R[i,j] > 0.0:
                e += pow(R[i,j] - P.row(i).dot(Qt.col(j)), 2.0)
                for k in 0..<rank:
                    e += (beta / 2.0) * (pow(P[i,k], 2.0) + pow(Qt[k,j], 2.0))
    return (P, Qt.transpose())

type StreamingALS* = ref object of RootObj
    ratings: Matrix
    rank: int
    itemFactorReg: float
    userFactorReg: float
    itemBiasReg: float
    userBiasReg: float
    nUsers: int
    nItems: int
    nSamples: int
    trainMSE: seq[float]
    testMSE: seq[float]
    userVecs: Matrix
    itemVecs: Matrix
    learningRate: float
    userBias: Vector
    itemBias: Vector
    globalBias: float

proc createStreamingALS(): StreamingALS =
    return StreamingALS.new()