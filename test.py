from z3 import Int, Solver, And, Distinct, Or, sat  # <1>

# Function to check if a given Sudoku solution is valid
def is_valid_sudoku(solution):
  n = len(solution)  # Determine the size of the grid  # <2>
  sqrt_n = int(n**0.5)  # Determine the size of subgrids  # <3>
  
  # Check if each row contains distinct values
  for row in solution:
    if len(set(row)) != n or any(x < 1 or x > n for x in row):  # Ensure values are within range and distinct
      return False  # <4>
  
  # Check if each column contains distinct values
  for j in range(n):
    col = [solution[i][j] for i in range(n)]  # Extract each column
    if len(set(col)) != n:
      return False  # <5>

  # Check if each sqrt_n x sqrt_n subgrid contains distinct values
  for i in range(0, n, sqrt_n):
    for j in range(0, n, sqrt_n):
      subgrid = []  # Collect the values of each subgrid
      for di in range(sqrt_n):
        for dj in range(sqrt_n):
          subgrid.append(solution[i + di][j + dj])
      if len(set(subgrid)) != n:  # Ensure distinct values in subgrid
        return False  # <6>

  return True  # If all checks pass, the solution is valid  # <7>

# Function to solve Sudoku puzzles where size is determined from the puzzle
def solve_sudoku(puzzle):
  n = len(puzzle)  # Determine the size of the grid from the puzzle list  # <8>
  
  # Create an n x n matrix of integer variables
  X = [[Int(f"x_{i}_{j}") for j in range(n)] for i in range(n)]  # <9>
  
  # Define the solver
  solver = Solver()  # <10>
  
  # Add constraints for cell values between 1 and n
  solver.add([And(X[i][j] >= 1, X[i][j] <= n) for i in range(n) for j in range(n)])  # <11>
  
  # Add constraints for the pre-filled cells
  solver.add([X[i][j] == puzzle[i][j] for i in range(n) for j in range(n) if puzzle[i][j] != 0])  # <12>
  
  # Add row constraints: each row must contain distinct values
  solver.add([Distinct(X[i]) for i in range(n)])  # <13>
  
  # Add column constraints: each column must contain distinct values
  solver.add([Distinct([X[i][j] for i in range(n)]) for j in range(n)])  # <14>
  
  # Add subgrid constraints: each sqrt_n x sqrt_n subgrid must contain distinct values
  sqrt_n = int(n**0.5)
  solver.add([Distinct([X[i + di][j + dj] for di in range(sqrt_n) for dj in range(sqrt_n)])
              for i in range(0, n, sqrt_n) for j in range(0, n, sqrt_n)])  # <15>
  
  # Find all possible solutions
  solutions = []  # List to store all solutions  # <16>
  while solver.check() == sat:  # <17>
    model = solver.model()
    solution = [[model.evaluate(X[i][j]).as_long() for j in range(n)] for i in range(n)]  # <18>
    solutions.append(solution)  # Store the solution  # <19>

    # Add a constraint to prevent finding the same solution again
    solver.add(Or([X[i][j] != solution[i][j] for i in range(n) for j in range(n)]))  # <20>
  
  return solutions  # Return all solutions  # <21>

# Example of a 4x4 Sudoku puzzle with multiple solutions
if __name__ == "__main__":
  # 4x4 Sudoku puzzle (0 represents empty cells)
  puzzle = [
    [1, 0, 0, 0, 5, 0, 0, 0, 9, 0, 0, 0, 13, 0, 0, 0],
    [0, 0, 0, 2, 0, 0, 0, 6, 0, 0, 0, 10, 0, 0, 0, 14],
    [0, 3, 0, 0, 0, 7, 0, 0, 0, 11, 0, 0, 0, 15, 0, 0],
    [4, 0, 0, 0, 8, 0, 0, 0, 12, 0, 0, 0, 16, 0, 0, 0],
    [0, 0, 0, 5, 0, 0, 0, 9, 0, 0, 0, 13, 0, 0, 0, 1],
    [0, 6, 0, 0, 0, 10, 0, 0, 0, 14, 0, 0, 0, 2, 0, 0],
    [0, 0, 7, 0, 0, 0, 11, 0, 0, 0, 15, 0, 0, 0, 3, 0],
    [8, 0, 0, 0, 12, 0, 0, 0, 16, 0, 0, 0, 4, 0, 0, 0],
    [0, 0, 0, 9, 0, 0, 0, 13, 0, 0, 0, 1, 0, 0, 0, 5],
    [0, 10, 0, 0, 0, 14, 0, 0, 0, 2, 0, 0, 0, 6, 0, 0],
    [0, 0, 11, 0, 0, 0, 15, 0, 0, 0, 3, 0, 0, 0, 7, 0],
    [12, 0, 0, 0, 16, 0, 0, 0, 4, 0, 0, 0, 8, 0, 0, 0],
    [0, 0, 0, 13, 0, 0, 0, 1, 0, 0, 0, 5, 0, 0, 0, 9],
    [0, 14, 0, 0, 0, 2, 0, 0, 0, 6, 0, 0, 0, 10, 0, 0],
    [0, 0, 15, 0, 0, 0, 3, 0, 0, 0, 7, 0, 0, 0, 11, 0],
    [16, 0, 0, 0, 4, 0, 0, 0, 8, 0, 0, 0, 12, 0, 0, 0]
  ]

  # Solve the Sudoku puzzle (size will be determined automatically)
  solutions = solve_sudoku(puzzle)  # <23>

  # Print all the solutions and check if they're valid
  print(f"Found {len(solutions)} solution(s):")
  for idx, solution in enumerate(solutions):
    print(f"Solution {idx + 1}:")
    for row in solution:
      print(row)  # <24>
    print()
    
    # Check if the solution is valid
    if is_valid_sudoku(solution):
      print("The solution is valid!")  # <25>
    else:
      print("The solution is not valid!")  # <26>
    print()
