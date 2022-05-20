# DS&A Flashcards

A repository to collate and store the data structures and algorithms flashcards to be used within dsaflash.cards.

## Getting Started

### Directory Structure

For now we will keep it simple. 
In the root directory a folder can be created for a "set" of cards. 
Inside this directory will then be the langauge specific sub-directories.

For example:

* Big O Notation
    * Any
* Queues
    * Go
        * pop.yml
    * Javascript

This format will likely change as per needs.

### Flashcard Structure

The flashcard is going to be a YAML file.
Initially this will have a basic structure, but can be updated as necessary. 

It is important that all flashcards are created with consistent naming and format.

```yaml
title: "Queue"
Front: |
    func (q *Queue) Pop() (MyQueueElement, bool) {
        if q.len <= 0 {
            return MyQueueElement{}, false
        }
        result := q.content[q.readHead]
        q.content[q.readHead] = MyQueueElement{}
        q.readHead = (q.readHead + 1) % MAX_QUEUE_SIZE
        q.len--
        return result, true
    }
Back: "Pop"
```

## Contributing

We will need contributors of different languages and topics so feel free to make a merge request and/or issue. 
You will need to follow the above structure guidelines unless otherwise discussed.