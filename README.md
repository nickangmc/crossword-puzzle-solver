## Solving Crossword Puzzle declaratively.
Program written and developed in the language Prolog as the final project for the subject COMP30020: Declarative Programming at the University of Melbourne - Semester 2, 2018. 

### Goal:

The aim of this project is to learn to program in the Declarative programming language - **Prolog**, as well as its prominent _backtracking_ feature that is in the core of the language Prolog. Without proper backtracking implementation, the program can easily get stuck in a infinite-backtracking loop, causing the puzzle solver to crash and fail as the puzzle size scales up. However, if it's being implemented properly, it can solve a large-scale puzzle faster than most of the algorithms implemented in imperative languages. 

---

### Example:

For a given **7x7 squares puzzle**:

![puzzle](https://github.com/nickangmc/crossword-puzzle-solver/blob/master/readme-images/puzzle.png)

- First, we have to input the _puzzle text-file_ into the program, formatted as **row-by-row arrays in a nested array**: with a black-out square represented by a _'#'_; a blank square represented by a _'\_'_ character; and a filled-in square represented by the corresponding _letter character_. E.g. the first row of the puzzle and the rest above can be represented as **[['#','#','\_','\_','\_','#','#'],...]**

- Then, we have to give it a _word list text-file_ that contains all the words that can be used to complete the puzzle. Words should be separated using a **newline character**, therefore each line in the text-file represents a word.

- Lastly, we input a _solution-file_ (any blank text-file with a name), which the program will use to store the answers to the puzzle. 

---

### Project Outcome
All the tasks and challenges within the scope of this project were completed.

