# AI/ML Fundamentals — Author Style Guide

This file is author-facing documentation. It is not loaded by the app. Its job is to pin vocabulary and tone so the AI/ML Fundamentals category stays consistent across the Wave 3 probe chunk and any follow-up chunks (T81-T84).

Target reader: non-ML engineers studying for interviews where AI/ML vocabulary shows up. Cards are tuned for 30-second whiteboard retrieval, not long-form comprehension.

## Vocabulary Pins

Use the chosen term. Do not drift into the "don't use" alternatives mid-lesson or mid-deck.

| Concept | Use | Don't use |
| --- | --- | --- |
| A trained ML system | **model** | "network", "architecture", "the AI" |
| Layered-computation structure | **neural network** (only when that structure is the topic) | as a synonym for "model" |
| The shape or type of a model | **architecture** (e.g., "transformer architecture") | as a synonym for "model" |
| Dense vector representation of an input | **embedding** | "vector" alone, "representation" |
| Atomic LLM input/output unit | **token** | "subword", "wordpiece" (in lessons) |
| Running a trained model on new input | **inference** | "prediction", "generation" as the primary term |
| Fitting a model to data | **training** | "learning" as the primary term |
| Continued training of a pretrained model | **fine-tuning** | "retraining", "training" (without the "fine-" prefix) |
| Learned numerical values of the model | **parameters** | "weights" as the primary term |
| Scalar measure of model wrongness | **loss** | "error", "cost" |
| Data used to fit the model | **training set** | "train data" |
| Data used to tune hyperparameters | **validation set** | "dev set", "holdout" |
| Final unseen evaluation data | **test set** | "holdout", "eval set" |
| Input text given to an LLM | **prompt** | "query", "instruction", "input" |

When a card or lesson genuinely needs to mention that parameters and weights are the same thing, do it once, in one place, and move on. Do not alternate.

## Tone Rules

- **Intuition over mechanism.** A four-minute lesson cannot teach transformers properly. Teach the shape of the idea. If the reader wants depth, they will go read Karpathy. What this category owns is fast retrieval under interview pressure.
- **No math-heavy notation.** No tensor shapes, no partial derivatives, no summation notation, no big-O of matrix multiplication. Plain English only. If an idea cannot be explained without math, it does not belong in an interview flashcard.
- **Concrete over abstract.** "A model that tells if a photo is a cat" beats "a binary classifier trained on labeled image data." The second sentence is for the back of the card, if at all.
- **Interview voice.** Every answer should sound like something you could actually say out loud at a whiteboard in 30 seconds. If it would take 90 seconds to read, it is too long.
- **Opinionated and direct.** "Never evaluate on training data" is better than "It is generally considered suboptimal to evaluate on training data."
- **No hype.** No "revolutionary", no "cutting-edge", no "state-of-the-art". The content half-life drops to zero the moment you type any of those words.

## "Never Include" List (content half-life guardrail)

These age badly. Do not include them in flashcards, quiz options, or lesson body text. If a future chunk needs to gesture at them, use the generic phrasing in parentheses.

- **Specific model names with versions.** No GPT-4, Claude 3.5 Sonnet, Llama 3.1, Gemini 1.5, Mistral Large. (Use "a large language model" or "a modern LLM".)
- **Specific context window sizes.** No 128k, no 1M tokens. (Use "varies by model".)
- **Current benchmark numbers.** No MMLU scores, no HumanEval percentages, no GSM8K figures.
- **"RLHF is the standard alignment method."** (Use "a common approach to alignment".)
- **Vector database brand names.** No Pinecone, Weaviate, Chroma, Milvus, pgvector. (Use "vector database".)
- **Current price-per-token figures.** These change monthly.
- **Novelty framing.** No "MoE is exotic", "MoE is experimental", "agents are new". The reader who sees this card six months after we write it will think we live under a rock.
- **Paper-by-year references.** No "Attention Is All You Need (2017)". (Use descriptive names: "the original transformer paper".)
- **Company-specific APIs and product features.** No OpenAI Realtime, Anthropic Computer Use, Google Live API.
- **Current SOTA claims.** Anything that says "the best" or "the leading" dies fast.

When in doubt, ask: would this card still be correct and current 18 months from now? If no, rewrite it.

## Schema Foot-Guns

Future content authors: read this section before writing anything. These are silent failure modes.

> ⚠️ **YAML key asymmetry — the #1 mistake.**
> - Flashcard YAML uses `lesson: ai-foundations` (key is `lesson`, singular, lowercase).
> - Quiz YAML uses `lesson_slug: "ai-foundations"` (key is `lesson_slug`).
>
> They populate the same database column but the YAML keys differ. If you write `lesson_slug:` in a flashcard file, seeding fails silently — no warning, no error, just a card that never appears. Double-check before committing.

> ⚠️ **Flashcard field capitalization.** `Front` and `Back` are capitalized. `front` and `back` (lowercase) are skipped. `title` is lowercase. Yes, it is inconsistent. The loader now warns in Wave 3 and later, but it still will not load the card.

> ⚠️ **Quiz questions must have exactly 4 options.** Three options or five options → the loader silently drops the question. Count them before committing. Every question, every time.

> ⚠️ **`correct` is an integer, not a string.** `correct: 0` (zero-indexed, 0 through 3). `correct: "A"` is wrong.

> ⚠️ **The flashcard file is a top-level list, not a dict.** Each card entry starts with `-`. The quiz file is a top-level dict with `title`, `lesson_slug`, `questions`. Don't confuse the two.

## Card Count Guidance

- **Probe phase:** 8-10 cards per chunk. Do not ship 15 cards on first-exposure material. The goal is to measure retention on a small deck, not to flood the user.
- **Post-probe:** If retention telemetry validates the chunk, counts can grow for later chunks. Let the data decide.
- Every card must pass the interview test: "Could a non-ML engineer who studied this card give a crisp 30-second answer at a whiteboard?" If the answer is maybe, the card is not ready.
