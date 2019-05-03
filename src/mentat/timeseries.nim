type EWMA = ref object of RootObj
    current: float
    average_age: float
    decay: float

proc newEWMA*(value: float, average_age: float = 30.0) : EWMA =
    let decay = 2 / (average_age + 1.0)
    EWMA(average_age: average_age, decay: decay, current: value)

proc update*(self: EWMA, value: float): float =
    self.current = (value * self.decay) + (self.current * (1 - self.decay))
    self.current
