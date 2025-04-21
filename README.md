# DS&A Flashcards

Flashcards for mastering **Data Structures & Algorithms** — the content behind **dsaflash.cards**.

---

## Project Structure

```text
/
├─ data_structures/          # basic DS decks
├─ advanced_data_structures/ # segment tree, trie, …
├─ algorithms/               # sorting, two‑pointer, DP, …
└─ README.md
```

*Every deck is a standalone `.yaml` file.*

If a deck needs language‑specific code, add sub‑folders:

```text
data_structures/
└─ stack/
   ├─ any/           # language‑agnostic cards
   └─ go/
      └─ stack.yaml
```

---

## Flashcard Format (`.yaml`)

```yaml
title: "Queue – Dequeue"
Front: |
    func (q *Queue) Dequeue() int {
        if len(*q) == 0 { return -1 }
        x := (*q)[0]
        *q = (*q)[1:]
        return x
    }
Back: "Dequeue (O(1))"
difficulty: "easy"
tags: ["queue", "dequeue"]
```

| Field        | Purpose                                    |
|--------------|--------------------------------------------|
| `title`      | Human‑readable card name (file header)     |
| `Front`      | Prompt — code, question, or description    |
| `Back`       | Answer / explanation                       |
| `difficulty` | *Optional* — easy, medium, hard            |
| `tags`       | *Optional* — quick search & grouping       |

Keep naming and formatting consistent — **one concept per file**.

---

## Contributing

Pull requests and issues are welcome!

* Follow the folder layout above.  
* Use the YAML schema shown.  
* One card per concept; feel free to add `difficulty` and `tags`.  
* Discuss major structure changes in an issue before opening a PR.
