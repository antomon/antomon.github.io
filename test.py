from z3 import Int, Function, Solver, IntSort, sat  # <1>

x = Int('x')  # <2>
y = Int('y')  # <3>

f = Function('f', IntSort(), IntSort())  # <4>

solver = Solver()  # <5>

solver.add(f(x) == y + 2)  # <6>
solver.add(f(3) == 5)  # <7>
solver.add(f(4) == 6)  # <8>
solver.add(f(7) == 10)  # <9>

if solver.check() == sat:  # <10>
  model = solver.model()  # <11>
  
  print(f"Solution: f(x) = {model.evaluate(f(x))}, y = {model.evaluate(y)}")  # <12>
  print(f"f(3) = {model.evaluate(f(3))}, f(4) = {model.evaluate(f(4))}, f(7) = {model.evaluate(f(7))}")  # <13>
  
else:
  print("No solution found")  # <14>

