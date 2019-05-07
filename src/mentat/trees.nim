import sequtils
import science/Functions as sci

type BBDTreeNode = ref object of RootObj
    dimension*: int
    count*: int
    indices*: int
    center*: seq[float]
    radius*: seq[float]
    cost*: float
    sum*: seq[float]
    leaf*: bool
    lower*: BBDTreeNode
    upper*: BBDTreeNode

proc newBBDTreeNode(dimension: int): BBDTreeNode =
    BBDTreeNode(
        dimension: dimension,
        count: 0,
        indices: 0,
        center: newSeqWith(dimension, 0.0),
        radius: newSeqWith(dimension, 0.0),
        cost: 0.0,
        sum: newSeqWith(dimension, 0.0),
        leaf: false,
        lower: nil,
        upper: nil
        )

proc box(self: BBDTreeNode, lower: seq[float], upper: seq[float]): (float, int) =
    var max_radius = -1.0
    var split = -1
    for i in 0..<self.dimension:
        self.center[i] = (lower[i] + upper[i]) / 2.0
        self.radius[i] = (upper[i] - lower[i]) / 2.0
        if self.radius[i] > max_radius:
            max_radius = self.radius[i]
            split = i
    return (max_radius, split)

func calculate_cost(self: BBDTreeNode, mean: seq[float]): float =
    var scatter = 0.0
    for i in 0..<self.dimension:
        let x = (self.sum[i] / float(self.count)) - mean[i]
        scatter += x * x
    return self.cost + float(self.count) * scatter

type BBDTree = ref object of RootObj
    dimension*: int
    indices*: seq[int]
    root*: BBDTreeNode
    membership*: seq[int]
    sums*: seq[seq[float]]
    counts*: seq[int]
    data: seq[seq[float]]

proc make(self: BBDTree, start: int, finish: int): BBDTreeNode =
    let d = self.dimension
    var node = newBBDTreeNode(d)

    node.count = finish - start
    node.indices = start

    # calculate the bounding box
    var lower_bound = newSeqWith(d, 0.0)
    var upper_bound = newSeqWith(d, 0.0)

    for i in 0..<d:
        let b = self.data[self.indices[start]][i]
        lower_bound[i] = b
        upper_bound[i] = b

    for i in (start+1)..<finish:
        for j in 0..<d:
            let c = self.data[self.indices[i]][j]
            if lower_bound[j] > c:
                lower_bound[j] = c
            if upper_bound[j] < c:
                upper_bound[j] = c
    
    # calculate bounding box
    let (max_radius, split) = node.box(lower_bound, upper_bound)

    if max_radius < 1e-10:

        for i in 0..<self.dimension:
            node.sum[i] = self.data[self.indices[start]][i]
            
        if finish > start + 1:
            let l = finish - start
            for i in 0..<d:
                node.sum[i] *= float(l)

        node.cost = 0.0
        node.leaf = true
        return node

    let split_cutoff = node.center[split]
    var index_a = start
    var index_b = finish - 1
    var size = 0

    while index_a <= index_b:
        var accept_index_a = self.data[self.indices[index_a]][split] < split_cutoff
        var accept_index_b = self.data[self.indices[index_b]][split] >= split_cutoff

        if (not accept_index_a) and (not accept_index_b):
            let tmp_a = self.indices[index_a]
            let tmp_b = self.indices[index_b]
            self.indices[index_a] = tmp_b
            self.indices[index_b] = tmp_a
            accept_index_a = true
            accept_index_b = true

        if accept_index_a:
            index_a += 1
            size += 1

        if accept_index_b:
            index_b -= 1
        
    node.lower = self.make(start, start + size)
    node.upper = self.make(start + size, finish)

    var mean = newSeqWith(d, 0.0)
    for i in 0..<d:
        node.sum[i] = node.lower.sum[i] + node.upper.sum[i]
        mean[i] = node.sum[i] / float(node.count)

    node.cost = node.lower.calculate_cost(mean) + node.upper.calculate_cost(mean)
    return node
    
proc closer(self: BBDTree, center: seq[float], radius: seq[float], centroids: seq[seq[float]], best: int, test: int): bool =
    if best == test:
        return false

    let best = centroids[best]
    let test = centroids[test]
    var left = 0.0
    var right = 0.0
    for i in 0..<self.dimension:
        let diff = test[i] - best[i]
        left += diff * diff
        if diff > 0:
            right += (center[i] + radius[i] - best[i]) * diff
        else:
            right += (center[i] - radius[i] - best[i]) * diff
    
    return left >= 2 * right

proc filter(self: BBDTree, node: BBDTreeNode, centroids: seq[seq[float]], candidates: seq[int], k: int): float =
    var min_dist = sci.squared_distance(node.center, centroids[candidates[0]])
    var closest = candidates[0]
    for i in 1..<k:
        let dist = sci.squared_distance(node.center, centroids[candidates[i]])
        if dist < min_dist:
            min_dist = dist
            closest = candidates[i]

    if not node.leaf:
        var new_candidate = newSeqWith(k, 0)
        var new_k = 0

        for i in 0..<k:
            if not self.closer(node.center, node.radius, centroids, closest, candidates[i]):
                new_candidate[new_k] = candidates[i]
                new_k += 1

        if new_k > 1:
            return self.filter(node.lower, centroids, new_candidate, new_k) + self.filter(node.upper, centroids, new_candidate, new_k)

    for i in 0..<self.dimension:
        self.sums[closest][i] += node.sum[i]

    self.counts[closest] += node.count
    let last = node.indices + node.count

    for i in node.indices..<last:
        self.membership[self.indices[i]] = closest

    return node.calculate_cost(centroids[closest])


proc clustering*(self: BBDTree, centroids: seq[seq[float]]): float =
    let k = len(centroids)

    self.membership = newSeqWith(len(self.indices), 0)
    self.sums = newSeqWith(k, newSeqWith(self.dimension, 0.0))
    self.counts = newSeqWith(k, 0)
    var candidates = newSeqWith(k, 0)
    for i in 0..<k:
        candidates[i] = i
    return self.filter(self.root, centroids, candidates, k)

proc newBBDTree*(data: seq[seq[float]]): BBDTree =
    let n = len(data)
    let dimension = len(data[0])
    var indices = newSeqWith(n, 0)
    for i in 0..<n:
        indices[i] = i
    let tree = BBDTree(
        dimension: dimension,
        indices: indices,
        root: nil,
        membership: @[],
        sums: @[],
        counts: @[],
        data: data
    )
    tree.root = tree.make(0, n)
    return tree
