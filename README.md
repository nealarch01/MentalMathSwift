# Mental Math Game Command Line Game
- Previously implemented in:
	- Go: https://github.com/nealarch01/mental-math-go
	- C++: https://github.com/nealarch01/mental-math-cpp

## Installation:
1. Clone this repository
2. Compile with swiftc: `swiftc -o <exec_name> main.swift`
	- `compile.sh` script compiles your code into an executable named `a`
	- `execc.sh` does what compile.sh does but executes it with a 10 second timer at level 1

## Usage:
- To use, you will need to add exec arguments. 
```sh
swiftc -o a main.swift
# ./a <duration> <level>
./a 60 1 # This initializes the game to be 60 seconds long and level easy
```
- There are three levels (easy, medium, hard)
	- To specify easy, set <level> = 1
	- Medium, set <level> = 2
	- Hard, set <level> = 3


# Video:









