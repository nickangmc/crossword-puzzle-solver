/*
 * COMP30020 Declaractive Programming
 * Project 2: Fillin Puzzles
 * Author: Mink Chen Ang <minka@student.unimelb.edu.au>
 * Purpose: Solve crossword puzzles from user provided puzzles and words lists.
 * Date Created: 4/10/2018
 *
 * The program will require user to enter a valid puzzle format and its
 * corresponding words list, along with the name of the output file for it
 * to print the puzzle with solutions filled in. The program then pre-processes
 * and transforms the puzzle format into list of lists with each element (list)
 * represents a valid word slot. Recursive search will be performed in order
 * to find a solution to the puzzle (each slot will be filled in), or even
 * multiple solutions for some puzzles. If a solution can be found, the
 * solution will be printed out to a file with the name user entered previously.
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
% Ensure the correct tranpose predicate will be used
:- ensure_loaded(library(clpfd)).

/* Main Functions */

% Main predicate that the user calls to solve a crossword puzzle.
% Reads puzzle file that has the name PuzzleFile, reads a word list file with
% name WordListFile, then validates the puzzle format and solves it. It prints
% the solution to the file with name SolutionFile.
% True if a valid solution has been found.
main(PuzzleFile, WordlistFile, SolutionFile) :-
	read_file(PuzzleFile, Puzzle),
	read_file(WordlistFile, Wordlist),
	valid_puzzle(Puzzle),
	solve_puzzle(Puzzle, Wordlist, Solved),
	print_puzzle(SolutionFile, Solved).

% Opens the specified file, reads the file line by line, and closes the file.
% True if file can be opened, read and closed.
read_file(Filename, Content) :-
	open(Filename, read, Stream),
	read_lines(Stream, Content),
	close(Stream).

% Read Stream line by line where each line will be stored as a list as an
% element in a list and end of the file determines the end of the list.
read_lines(Stream, Content) :-
	read_line(Stream, Line, Last),
	(   Last = true
	->  (   Line = []
	    ->  Content = []
	    ;   Content = [Line]
	    )
	;  Content = [Line|Content1],
	    read_lines(Stream, Content1)
	).

% Read one line of the Stream character by character. Each characters read will
% be stored as an element in a list, where a newline character or end of the
% file determines end of the list. Hence, each line of Stream will be stored
% as a list. If end of the file is reached, return Last as true, false
% otherwise.
read_line(Stream, Line, Last) :-
	get_char(Stream, Char),
	(   Char = end_of_file
	->  Line = [],
	    Last = true
	; Char = '\n'
	->  Line = [],
	    Last = false
	;   Line = [Char|Line1],
	    read_line(Stream, Line1, Last)
	).

% Open a file with name SolutionFile: if such file exists, it will be
% overwritten; if no such file exists, a new file will be created.
% Hence, a Stream variable will now represent the content of the SolutionFile.
% Read the puzzle row by row (list by list) and write the results out to
% the Stream and closes Stream at the end.
print_puzzle(SolutionFile, Puzzle) :-
	open(SolutionFile, write, Stream),
	maplist(print_row(Stream), Puzzle),
	close(Stream).

% Reads and outputs the content of Row to Stream character by character.
% A new line will be inserted to Stream at the end of each Row.
print_row(Stream, Row) :-
	maplist(put_puzzle_char(Stream), Row),
	nl(Stream).

% Reads and outputs each character accordingly to the Stream. If a Char is
% Variable, then a '_' character will be put into Stream, else the initial
% value of the Char will be put into Stream.
put_puzzle_char(Stream, Char) :-
	(   var(Char)
	->  put_char(Stream, '_')
	;   put_char(Stream, Char)
	).

% True if each row in the puzzle has the same length.
valid_puzzle([]).
valid_puzzle([Row|Rows]) :-
	maplist(same_length(Row), Rows).

% True if puzzle can be preprocessed and solved.
solve_puzzle(Puzzle, WordList, Solved) :-
	preprocess_puzzle(Puzzle, Solved, Preprocessed),
	fill_slots(Preprocessed, WordList).

/****************************************************************/
/* Puzzle Pre-processing and its Helper Functions */

% Prepare and transform puzzle so that it can be accessed and processed with
% ease.
% E.g.
% [['_','_','_'],['_','_','#'],['_','_','_']] -> [[X1,X2,X3],[Y1,Y2],[Z1,Z2,Z3]]
preprocess_puzzle(Puzzle, Solution, Preprocessed) :-
	elem_to_var(Puzzle, Solution),
	incl_transposed(Solution, AllSlots),
	get_fillable_slots(AllSlots, ConsistentSlots),
	delete_short_slots(ConsistentSlots, Preprocessed).


% Traverse through each slot in the puzzle and replace elements in the slot
% with variables accordingly.
elem_to_var([], []).
elem_to_var([X|Xs], [Y|Ys]) :-
	replace_with_var(X, Y),
	elem_to_var(Xs, Ys).


% Replace all the characters of '_' in a slot with variables, while characters
% of '#' or a prefilled element will be retained.
replace_with_var([], []).
replace_with_var([X|Xs], [Y|Ys]) :-
	(	X = '#'
	->	Y = '#',
		replace_with_var(Xs, Ys)
	;	X \== '_'
	->	Y = X,
		replace_with_var(Xs, Ys)
	;	length(V, 1),
		V = [Y|_],
		replace_with_var(Xs, Ys)
	).


% Tranpose the input puzzle slots, append the tranposed slots to AllSlots.
incl_transposed(Puzzle, AllSlots) :-
	transpose(Puzzle, PuzzleT),
	append(Puzzle, PuzzleT, AllSlots).


% Traverse through each slot in AllSlots to get fillable elements in each
% slot, then extracts all nested fillable elements so that each fillable
% element is now a slot on its own in AllSlots :
% E.g. [[X1,X2,X3,'#',Y1,Y2,Y3],[Z1,Z2]] -> [[X1,X2,X3],[Y1,Y2,Y3],[Z1,Z2]]
get_fillable_slots(AllSlots, ConsistentSlots) :-
	get_fillable_slots_acc(AllSlots, [], ConsistentSlots).

get_fillable_slots_acc([], Acc, Acc).
get_fillable_slots_acc(AllSlots, Acc, ConsistentSlots) :-
	AllSlots = [X|Xs],
	get_fillable_slot(X, NewX),
	extract_slots(NewX, Acc, NewAcc),
	get_fillable_slots_acc(Xs, NewAcc, ConsistentSlots).


% Find and get word slots (fillable element) by separating elements in the
% specified slot by the character '#' :
% E.g. [X1,X2,X3,'#',Y1,Y2,Y3] -> [[X1,X2,X3],[Y1,Y2,Y3]]
get_fillable_slot(Slot, WordSlots) :-
	get_fillable_slot_acc(Slot, [], [], WordSlots).

get_fillable_slot_acc([], Acc, BigAcc, WordSlots) :-
	(	Acc = []
	->	WordSlots = BigAcc
	;	append(BigAcc, [Acc], NewBigAcc),
		WordSlots = NewBigAcc
	).

get_fillable_slot_acc(Slot, Acc, BigAcc, WordSlots) :-
	Slot = [X|Xs],
	(	X \== '#'
	->	append(Acc, [X], NewAcc),
		get_fillable_slot_acc(Xs, NewAcc, BigAcc, WordSlots)
	;	append(BigAcc, [Acc], NewBigAcc),
		get_fillable_slot_acc(Xs, [], NewBigAcc, WordSlots)
	).


% Take in an Acc (accumulator of list), whether it be an empty list or a
% non-empty list, and append each element in Slot to Acc. Extracted will be
% the resulted list of initial Acc appended with each and every element in the
% Slot.
extract_slots([], Acc, Acc).
extract_slots(Slot, Acc, Extracted) :-
	Slot = [X|Xs],
	append(Acc, [X], NewAcc),
	extract_slots(Xs, NewAcc, Extracted).


% Delete slots from AllSlots that has length less than 2 as they are not
% required (no words in word list will be shorter than 2).
delete_short_slots(AllSlots, Filtered) :-
	delete_short_slots_acc(AllSlots, [], Filtered).

delete_short_slots_acc([], Acc, Acc).
delete_short_slots_acc([X|Xs], Acc, Filtered) :-
	length(X, N),
	(	N > 1
	->	append(Acc, [X], NewAcc),
		delete_short_slots_acc(Xs, NewAcc, Filtered)
	;	delete_short_slots_acc(Xs, Acc, Filtered)
	).


/****************************************************************/
/* Puzzle Filling and its Helper Functions */

% Fill in slots with selected words that can minimize future search space
% (minimize overall permutations) only once, then recursively search and
% for most filled slots (either by pre-filled or indirectly filled) and fill
% them in.
% If partially filled slots do not match with any word in the WordList, it
% suggests that it is not the right permutation, hence the program will
% directly backtrack to the initial find_least_permutations part.
% Therefore, it cuts down a lot of avoidable backtrackings and permutations.
fill_slots(AllSlots, WordList) :-
	find_least_permutations(AllSlots, WordList, NewSlots, NewWordList),
	fill_most_filled_slot(NewSlots, NewWordList).


% Find out a combinations words that can minimize future search space
% (minimize overall permutations)
find_least_permutations(AllSlots, WordList, NewSlots, NewWordList) :-
	get_length_group(WordList, LengthGroup),
	length_with_least_elems(WordList, LengthGroup, Length),
	get_elems_of_length(AllSlots, Length, SelectedSlots),
	get_elems_of_length(WordList, Length, SelectedWords),
	subtract(WordList, SelectedWords, NewWordList),
	subtractMember(SelectedSlots, AllSlots, NewSlots),
	fill_slot(SelectedSlots, SelectedWords).


% Fill in specified Slots with specified Words while making sure the words
% fit the existing conditions of the slots (E.g. partially pre-filled slots,
% etc.)
fill_slot([], []).
fill_slot(Slots, Words) :-
	Slots = [X|Xs],
	member(X, Words),
	delete(Words, X, RemainingWords),
	delMember(X, Slots, Xs),
	fill_slot(Xs, RemainingWords).


% Recursively find and fill most filled slots (either by pre-filled or
% indirectly filled).
fill_most_filled_slot([], []).
fill_most_filled_slot(AllSlots, WordList) :-
	find_most_filled_slot(AllSlots, X),
	member(X, WordList),
	delete(WordList, X, NewWordList),
	delMember(X, AllSlots, Xs),
	fill_most_filled_slot(Xs, NewWordList).


% Find most filled slots (either by pre-filled or indirectly filled).
% Since we only need one of the most filled slots (assuming there are many
% equal-in-length filled slots), so once such slot has been found, cut
% operator is used to prevent unnecessary backtrackings.
find_most_filled_slot(Slots, SelectedSlot) :-
	find_most_filled_slot_acc(Slots, 0, _, SelectedSlot),
	!.

find_most_filled_slot_acc([], _, Slot, Slot).
find_most_filled_slot_acc(Slots, Acc, Slot, SelectedSlot) :-
	Slots = [X|Xs],
	nonvar_length(X, N),
	(	N >= Acc
	->	find_most_filled_slot_acc(Xs, N, X, SelectedSlot)
	;	find_most_filled_slot_acc(Xs, Acc, Slot, SelectedSlot)
	).


% Traverse through WordList and collect length of each word and group the
% lengths together in a list.
get_length_group(List, LengthGroup):-
	List = [X|_],
	length(X, N),
	get_length_group_acc(List, N, [N], LengthGroup).

get_length_group_acc([], _, ListAcc, ListAcc).
get_length_group_acc(WordList, Acc, ListAcc, LengthGroup) :-
	WordList = [X|Xs],
	length(X, N),
	(	member(N, ListAcc)
	->	get_length_group_acc(Xs, Acc, ListAcc, LengthGroup)
	;	append([N], ListAcc, NewListAcc),
		get_length_group_acc(Xs, N, NewListAcc, LengthGroup)
	).


% Traverse through LengthGroup and find out the number of elements in the list
% that have the same length as the length value for each of the length value
% in LengthGroup. Retain only the LengthValue that has the least elements that
% have the same length as the LengthValue.
length_with_least_elems(List, LengthGroup, LengthValue) :-
	length_with_least_elems_acc(List, LengthGroup, 999, _, LengthValue).

length_with_least_elems_acc(_, [], _, Temp, Temp).
length_with_least_elems_acc(List, LengthGroup, Acc, Temp, Length) :-
	LengthGroup = [X|Xs],
	find_same_length(List, X, NumOfElems),
	(	NumOfElems < Acc
	->	length_with_least_elems_acc(List, Xs, NumOfElems, X, Length)
	;	length_with_least_elems_acc(List, Xs, Acc, Temp, Length)
	).


% Find out the number of elements in the specified List that have the same
% length as the LengthValue, return the number of elements as NumOfElems.
find_same_length(List, LengthValue, NumOfElems) :-
	find_same_length_acc(List, LengthValue, 0, NumOfElems).

find_same_length_acc([], _, Acc, Acc).
find_same_length_acc(List, LengthValue, Acc, NumOfElems) :-
	List = [X|Xs],
	length(X, N),
	(	N =:= LengthValue
	->	AccNew is Acc + 1,
		find_same_length_acc(Xs, LengthValue, AccNew, NumOfElems)
	;	find_same_length_acc(Xs, LengthValue, Acc, NumOfElems)
	).


% Get all elements from the specified List that have the length of Length and
% return them as SelectedElems.
get_elems_of_length(List, Length, SelectedElems) :-
	get_elems_of_length_acc(List, Length, [], SelectedElems).

get_elems_of_length_acc([], _, Acc, Acc).
get_elems_of_length_acc(List, Length, Acc, SelectedElems) :-
	List = [X|Xs],
	length(X, N),
	(	N =:= Length
	->	append([X], Acc, NewAcc),
		get_elems_of_length_acc(Xs, Length, NewAcc, SelectedElems)
	;	get_elems_of_length_acc(Xs, Length, Acc, SelectedElems)
	).


/****************************************************************/
/* General Helper Functions */

% Referenced From: https://stackoverflow.com/questions/37635984/prolog-remove-
%				  member-of-list-with-non-instantiated-values
% Delete matching atom terms in the list only without deleting variables that
% could be unified to match the input element, unlike delete/3
delMember(_, [], []).
delMember(X, [X1|Xs], Ys) :- X == X1, delMember(X, Xs, Ys).
delMember(X, [X1|Xs], [X1|Ys]) :- X \== X1, delMember(X, Xs, Ys).


% Similar idea to delMember but for deleting multiple elements in a list
subtractMember([], AllSlots, AllSlots).
subtractMember([X|Xs], AllSlots, NewSlots) :-
	delMember(X, AllSlots, NewAllSlots),
	subtractMember(Xs, NewAllSlots, NewSlots).


% Find the number of non-variable elements in a list.
nonvar_length(Word, Length) :-
	nonvar_length_acc(Word, 0, Length).

nonvar_length_acc([], Acc, Acc).
nonvar_length_acc(Word, Acc, Length) :-
	Word = [X|Xs],
	(	nonvar(X)
	->	AccNew is Acc + 1,
		nonvar_length_acc(Xs, AccNew, Length)
	;	nonvar_length_acc(Xs, Acc, Length)
	).


/****************************************************************/

% End of File

