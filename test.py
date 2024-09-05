from z3 import Int, Solver, And, Distinct, Or, sat  # <1>

# Function to solve Sudoku puzzles where size is determined from the puzzle
def solve_sudoku(puzzle):
  n = len(puzzle)  # Determine the size of the grid from the puzzle list  # <2>
  
  # Create an n x n matrix of integer variables
  X = [[Int(f"x_{i}_{j}") for j in range(n)] for i in range(n)]  # <3>
  
  # Define the solver
  solver = Solver()  # <4>
  
  # Add constraints for cell values between 1 and n
  solver.add([And(X[i][j] >= 1, X[i][j] <= n) for i in range(n) for j in range(n)])  # <5>
  
  # Add constraints for the pre-filled cells
  solver.add([X[i][j] == puzzle[i][j] for i in range(n) for j in range(n) if puzzle[i][j] != 0])  # <6>
  
  # Add row constraints: each row must contain distinct values
  solver.add([Distinct(X[i]) for i in range(n)])  # <7>
  
  # Add column constraints: each column must contain distinct values
  solver.add([Distinct([X[i][j] for i in range(n)]) for j in range(n)])  # <8>
  
  # Add subgrid constraints: each sqrt_n x sqrt_n subgrid must contain distinct values
  sqrt_n = int(n**0.5)
  solver.add([Distinct([X[i + di][j + dj] for di in range(sqrt_n) for dj in range(sqrt_n)])
              for i in range(0, n, sqrt_n) for j in range(0, n, sqrt_n)])  # <9>
  
  # Find all possible solutions
  solutions = []  # List to store all solutions
  while solver.check() == sat:  # <10>
    model = solver.model()
    solution = [[model.evaluate(X[i][j]).as_long() for j in range(n)] for i in range(n)]  # <11>
    solutions.append(solution)  # Store the solution  # <12>

    # Add a constraint to prevent finding the same solution again
    solver.add(Or([X[i][j] != solution[i][j] for i in range(n) for j in range(n)]))  # <13>
  
  return solutions  # Return all solutions  # <14>

# Example of a 4x4 Sudoku puzzle with multiple solutions
if __name__ == "__main__":
  # 4x4 Sudoku puzzle (0 represents empty cells)
  puzzle = [
    [1, 0, 0, 4],
    [0, 0, 0, 0],
    [0, 0, 0, 0],
    [4, 0, 0, 1]
  ]  # <15>

  # Solve the Sudoku puzzle (size will be determined automatically)
  solutions = solve_sudoku(puzzle)  # <16>

  # Print all the solutions
  print(f"Found {len(solutions)} solution(s):")
  for idx, solution in enumerate(solutions):
    print(f"Solution {idx + 1}:")
    for row in solution:
      print(row)  # <17>
    print()
