import science/Distributions
import mentat/trees
import matplotnim
import sequtils

let n = 1000
let px = concat(rnorm(n, 0.0, 1.0), rnorm(n, 3.0, 1.0))
let py = concat(rnorm(n, 0.0, 1.0), rnorm(n, 3.0, 1.0))

var points:seq[seq[float]] = @[]
for i in 0..<2*n:
    points.add @[px[i], py[i]]
    
let tree = newBBDTree(points)
let c1 = @[0.0, 0.0]
let c2 = @[3.0, 3.0]
discard tree.clustering(@[c1, c2])

echo tree.membership

let f = newFigure()
f.add newScatterPlot(px, py)
f.save("examples/bbdtree_data.png")

var cluster1x:seq[float] = @[]
var cluster1y:seq[float] = @[]
var cluster2x:seq[float] = @[]
var cluster2y:seq[float] = @[]
for i in 0..<len(tree.membership):
    if tree.membership[i] == 0:
        cluster1x.add px[i]
        cluster1y.add py[i]
    else:
        cluster2x.add px[i]
        cluster2y.add py[i]

let f2 = newFigure()
let sp1 = newScatterPlot(cluster1x, cluster1y)
sp1.colour = "red"
f2.add sp1
let sp2 = newScatterPlot(cluster2x, cluster2y)
sp2.colour = "blue"
f2.add sp2
f2.save("examples/bbdtree_clusters.png")