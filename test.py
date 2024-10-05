class Graph:
  def __init__(self):
    self.graph = {}

  # Add a vertex to the graph
  def add_vertex(self, vertex):
    if vertex not in self.graph:
      self.graph[vertex] = []

  # Add an edge between two vertices
  def add_edge(self, vertex1, vertex2):
    if vertex1 in self.graph and vertex2 in self.graph:
      self.graph[vertex1].append(vertex2)
      self.graph[vertex2].append(vertex1)  # Assuming an undirected graph

  # Check if an edge exists between two vertices
  def has_edge(self, vertex1, vertex2):
    return vertex2 in self.graph.get(vertex1, [])

  # Depth First Search (DFS) traversal
  def dfs(self, start, visited=None):
    if visited is None:
      visited = set()

    visited.add(start)
    print(start, end=' ')

    for neighbor in self.graph[start]:
      if neighbor not in visited:
        self.dfs(neighbor, visited)

  # Breadth First Search (BFS) traversal
  def bfs(self, start):
    visited = set()
    queue = [start]
    visited.add(start)

    while queue:
      vertex = queue.pop(0)
      print(vertex, end=' ')

      for neighbor in self.graph[vertex]:
        if neighbor not in visited:
          queue.append(neighbor)
          visited.add(neighbor)

  # Find all connected components
  def connected_components(self):
    visited = set()
    components = []

    for vertex in self.graph:
      if vertex not in visited:
        component = []
        self._dfs_component(vertex, visited, component)
        components.append(component)

    return components

  # Helper function for DFS within a component
  def _dfs_component(self, vertex, visited, component):
    visited.add(vertex)
    component.append(vertex)

    for neighbor in self.graph[vertex]:
      if neighbor not in visited:
        self._dfs_component(neighbor, visited, component)

  # Display the graph
  def display_graph(self):
    for vertex in self.graph:
      print(f"{vertex} -> {', '.join([str(v) for v in self.graph[vertex]])}")


# Example usage
g = Graph()
g.add_vertex('A')
g.add_vertex('B')
g.add_vertex('C')
g.add_vertex('D')
g.add_vertex('E')

g.add_edge('A', 'B')
g.add_edge('A', 'C')
g.add_edge('B', 'D')
g.add_edge('D', 'E')

# Display the graph
g.display_graph()

# Check if an edge exists
print("\nEdge A-B:", g.has_edge('A', 'B'))
print("Edge A-E:", g.has_edge('A', 'E'))

# Traverse the graph using DFS
print("\nDFS traversal starting from A:")
g.dfs('A')

# Traverse the graph using BFS
print("\n\nBFS traversal starting from A:")
g.bfs('A')

# Find and display all connected components
print("\n\nConnected Components:")
components = g.connected_components()
for i, component in enumerate(components, 1):
    print(f"Component {i}: {component}")
