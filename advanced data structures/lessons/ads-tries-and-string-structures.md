---
title: "Tries and String Structures"
summary: "Trie (prefix tree) structure, insert and search in O(k), prefix matching, and suffix arrays for substring search. When to use each."
reading_time_minutes: 5
order: 1
---

## Why This Matters

String-heavy problems are everywhere in interviews: autocomplete, spell checkers, IP routing tables, and genome sequence search all rely on specialized string data structures. A hash map handles exact lookup in O(k), but the moment a problem asks about prefixes — "find all words starting with 'pre'" — you need something better. Tries and suffix arrays are the two structures that come up most often.

## The Trie (Prefix Tree)

A trie stores strings character-by-character. Each node represents a single character, and a path from root to a marked node spells a complete word.

```
insert("app"), insert("apple"), insert("apply")

root
 └─ a
     └─ p
         └─ p  [isEnd=true]  ("app")
             └─ l
                 ├─ e  [isEnd=true]  ("apple")
                 └─ y  [isEnd=true]  ("apply")
```

Each node typically holds an array or map of children (one per possible character) and a boolean `isEnd` flag.

### Why the isEnd Flag Matters

Without `isEnd`, searching for "app" in a trie containing "apple" would return a false positive — the traversal reaches the 'p' node but cannot tell whether "app" itself was ever inserted. The `isEnd` flag distinguishes complete words from internal prefixes.

### Insert and Search: O(k)

Both insert and search are O(k), where k is the length of the string being inserted or searched. Each character corresponds to exactly one edge traversal, so the operation is proportional to the string length, not the number of stored strings.

```
insert(word):
    node = root
    for each character c in word:
        if node has no child for c:
            create new child node
        node = child[c]
    node.isEnd = true

search(word):
    node = root
    for each character c in word:
        if node has no child for c:
            return false
        node = child[c]
    return node.isEnd

prefix_search(prefix):
    node = root
    for each character c in prefix:
        if node has no child for c:
            return false
        node = child[c]
    return true  // any word with this prefix exists
```

### Space Trade-Off

The main cost of a trie is memory. Each node must store a reference for every possible character in the alphabet. For ASCII (128 characters) or Unicode, this can be expensive. In practice, use a hash map of children instead of a fixed array to avoid allocating space for unused characters.

- **Time:** O(k) insert, O(k) search, O(k) prefix search
- **Space:** O(ALPHABET_SIZE × n × k) worst case for an array-backed trie, where n is the number of strings

### When to Use a Trie vs a Hash Map

| Need | Prefer |
|---|---|
| Exact key lookup only | Hash map — simpler, less memory |
| Prefix search, autocomplete | Trie |
| Sorted iteration over keys | Trie (keys emerge in lexicographic order) |
| Counting words with a shared prefix | Trie (track subtree count per node) |

A hash map wins on simplicity when you only need exact lookups. A trie wins the moment prefix operations enter the picture.

## Suffix Arrays

A suffix array stores the starting indices of all suffixes of a string, sorted lexicographically. For the string `"banana"`:

| Suffix | Start Index |
|---|---|
| `"a"` | 5 |
| `"ana"` | 3 |
| `"anana"` | 1 |
| `"banana"` | 0 |
| `"na"` | 4 |
| `"nana"` | 2 |

Suffix array: `[5, 3, 1, 0, 4, 2]`

### Substring Search via Binary Search

Because the suffix array is sorted, you can binary search for any pattern in O(m log n) time, where m is the pattern length and n is the string length. At each binary search step, compare the pattern against the prefix of the suffix at the midpoint.

### Building a Suffix Array

- **Naive:** Sort all n suffixes using string comparison — O(n² log n). Impractical for large strings.
- **O(n log² n):** Use a doubling trick: sort by first character, then by first two characters, then four, etc.
- **O(n) linear:** SA-IS algorithm. Complex to implement but optimal. Used in production text indexing.

For interviews, knowing that an O(n log n) or O(n) construction exists is sufficient — you won't be asked to code SA-IS from scratch.

### Suffix Array vs Suffix Tree

A suffix tree gives O(m) substring search (vs. O(m log n) for suffix array), but uses significantly more memory and is much harder to implement correctly. A suffix array is the practical choice unless O(m) search is required.

## Key Takeaways

- A trie stores strings character-by-character, giving O(k) insert and search, where k is the string length.
- The `isEnd` flag distinguishes complete words from internal prefixes — without it, searching for "app" matches inside "apple."
- Tries use more memory than hash maps, especially with large alphabets. Use a child map instead of a fixed array when the alphabet is sparse.
- A suffix array holds sorted suffix indices and enables O(m log n) substring search via binary search.
- Use a trie for prefix search and autocomplete. Use a suffix array for substring search over large texts.
