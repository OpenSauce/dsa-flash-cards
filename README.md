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
        * dequeue.yml
    * Javascript

This format will likely change as per needs.

### Flashcard Structure

The flashcard is going to be a YAML file.
Initially this will have a basic structure, but can be updated as necessary. 

It is important that all flashcards are created with consistent naming and format.

```yaml
title: "Queue"
Front: |
    func (queue *Queue) <?>() int {
        if len(queue) <= 0 {
            return -1
        }
        head := queue[0]
        queue = queue[1:]
        return head
    }
Back: "Dequeue"
Options: "Pop,Queue"
```

## Contributing

We will need contributors of different languages and topics so feel free to make a merge request and/or issue. 
You will need to follow the above structure guidelines unless otherwise discussed.