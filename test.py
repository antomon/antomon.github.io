from z3 import Int, Solver, And, Distinct, sat  # <1>

# Function to check if the solved Sudoku is correct
def is_valid_sudoku(board):
  # Combined row and column checks in a single loop
  for i in range(9):
    # Check distinct values in row
    if len(set(board[i])) != 9:  
      return False  # <2>
    
    # Check distinct values in column
    col = [board[j][i] for j in range(9)]
    if len(set(col)) != 9:
      return False  # <3>

  # Check 3x3 subgrids
  for i in range(0, 9, 3):
    for j in range(0, 9, 3):
      subgrid = [board[i + di][j + dj] for di in range(3) for dj in range(3)]
      if len(set(subgrid)) != 9:
        return False  # <4>

  return True  # <5>

# Function to solve a Sudoku puzzle using Z3
def solve_sudoku(puzzle):
  # Create a 9x9 matrix of integer variables
  X = [[Int(f"x_{i}_{j}") for j in range(9)] for i in range(9)]  # <6>
  
  # Define the solver
  solver = Solver()  # <7>
  
  # Add constraints for cell values between 1 and 9
  solver.add([And(X[i][j] >= 1, X[i][j] <= 9) for i in range(9) for j in range(9)])  # <8>
  
  # Add constraints for the pre-filled cells
  solver.add([X[i][j] == puzzle[i][j] for i in range(9) for j in range(9) if puzzle[i][j] != 0])  # <9>
  
  # Add constraints for rows, columns, and subgrids to contain distinct values
  solver.add([Distinct(X[i]) for i in range(9)])  # Row distinct  # <10>
  solver.add([Distinct([X[i][j] for i in range(9)]) for j in range(9)])  # Column distinct  # <11>
  solver.add([Distinct([X[i + di][j + dj] for di in range(3) for dj in range(3)])
              for i in range(0, 9, 3) for j in range(0, 9, 3)])  # Subgrid distinct  # <12>
  
  # Check if the Sudoku puzzle is solvable
  if solver.check() == sat:  # <13>
    model = solver.model()
    result = [[model.evaluate(X[i][j]).as_long() for j in range(9)] for i in range(9)]  # <14>
    return result  # <15>
  else:
    return None  # <16>

# Example of solving and checking a Sudoku puzzle
if __name__ == "__main__":
  # Input Sudoku puzzle (0 represents empty cells)
  puzzle = [
    [5, 3, 0, 0, 7, 0, 0, 0, 0],
    [6, 0, 0, 1, 9, 5, 0, 0, 0],
    [0, 9, 8, 0, 0, 0, 0, 6, 0],
    [8, 0, 0, 0, 6, 0, 0, 0, 3],
    [4, 0, 0, 8, 0, 3, 0, 0, 1],
    [7, 0, 0, 0, 2, 0, 0, 0, 6],
    [0, 6, 0, 0, 0, 0, 2, 8, 0],
    [0, 0, 0, 4, 1, 9, 0, 0, 5],
    [0, 0, 0, 0, 8, 0, 0, 7, 9]
  ]  # <17>

  # Solve the Sudoku puzzle
  solved = solve_sudoku(puzzle)  # <18>

  # Print the solved Sudoku puzzle and check if it's valid
  if solved:
    for row in solved:
      print(row)  # <19>
    # Check if the solution is valid
    if is_valid_sudoku(solved):
      print("The solution is valid!")  # <20>
    else:
      print("The solution is not valid!")  # <21>
  else:
    print("No solution found.")  # <22>
