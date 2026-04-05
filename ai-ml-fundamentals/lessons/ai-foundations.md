---
title: "AI/ML Foundations"
summary: "The vocabulary every non-ML engineer needs: supervised vs unsupervised, training vs inference, overfitting, and why model choice is a tradeoff."
reading_time_minutes: 4
order: 1
---

## Why This Matters

You do not need to be an ML researcher to work on AI-adjacent projects, but you do need to speak the language. Product reviews, system design interviews, and architecture discussions increasingly assume you know the difference between training and inference, or what overfitting looks like in practice. Engineers who fumble this vocabulary lose credibility fast, even when the rest of their technical judgment is sound.

This lesson covers the 30,000-foot view: what ML actually is, the three main flavors of learning, the training/inference split that shapes every ML system design, and the single most common beginner trap (overfitting). The goal is not to make you an ML engineer. The goal is to let you hold your own in a conversation with one, and to give crisp answers when an interviewer asks the basics.

## AI vs ML vs DL

Three terms, three scopes. **AI (artificial intelligence)** is the broad goal: building systems that do things we would call intelligent. **ML (machine learning)** is the dominant approach to getting there: instead of writing rules by hand, you let a system learn patterns from data. **DL (deep learning)** is a subset of ML that uses deep neural networks, meaning networks with many layers. Every deep learning system is an ML system. Every ML system is an AI system. The reverse is not true. Do not conflate these in interviews, especially AI and ML, which get swapped constantly in casual speech but mean different things on a whiteboard.

## The Three Flavors of Learning

Almost every ML technique you will hear about falls into one of three categories.

**Supervised learning** uses labeled examples. You show the model a bunch of inputs paired with the right answers, and it learns to predict the answer for new inputs. Spam detection is the canonical example: thousands of emails labeled spam or not-spam, and the model learns to classify new emails.

**Unsupervised learning** uses no labels. You give the model a pile of data and ask it to find structure on its own. Clustering users into behavioral groups from usage logs is a typical example. Nobody told the model what the groups should be; it discovers them.

**Reinforcement learning** uses a reward signal instead of labels. An agent takes actions, receives a reward or penalty, and learns to act in ways that maximize long-term reward. Game-playing agents are the famous example. The model is not told what move is correct, only whether the outcome was good.

## Training vs Inference

This is the single most important distinction in ML system design. **Training** is the expensive process of fitting the model's parameters to data. It usually happens once, or periodically, and it can take hours, days, or weeks on specialized hardware. **Inference** is running the finished model on new input to get an answer. Inference is cheap per call, fast, and happens constantly in production. When someone asks "where does the cost live in your ML system", they are asking you to locate the training and inference workloads separately, because they have completely different scaling profiles, hardware needs, and latency requirements.

## Train/Val/Test Split

You do not train on all your data. You split it into three sets, each with a different job. The **training set** is what the model learns from. The **validation set** is what you use to tune hyperparameters and pick between model variants. The **test set** is touched only at the very end, to give an honest estimate of how the model performs on data it has never seen. If you evaluate on data the model trained on, your numbers are meaningless, because the model has already seen the answers. If you leak test data into training, even indirectly, you invalidate your final score. Interviewers love to probe this because it is the easiest way to tell who has actually worked with ML data and who has only read about it.

## Loss and Gradient Descent (Intuition)

**Loss** is one number that says "how wrong is the model right now?" Training is the process of nudging the model's parameters in directions that push the loss down. **Gradient descent** is the algorithm that does the nudging. It looks at the slope of the loss with respect to each parameter and takes a small step downhill. Repeat millions of times. You do not need the calculus to talk about this in interviews. You need the shape of the idea: loss is a scalar wrongness score, and training is a search for parameters that make it small.

## Overfitting: The Beginner Trap

**Overfitting** is when a model memorizes its training data instead of learning general patterns. The symptom is unmistakable: accuracy is great on the training set and terrible on the test set. The model has learned the noise in the training examples, not the underlying signal, so it fails the moment you show it anything new.

Standard mitigations all attack the same root cause, which is that the model has too much capacity relative to the amount of real signal in the data. More training data helps. A simpler model helps. Regularization (penalizing overly complex parameter values) helps. Early stopping (stop training when validation loss stops improving) helps. Dropout (randomly zeroing out parts of the model during training) helps. In an interview, you do not need to explain the mechanisms in depth. You need to name the symptom (train accuracy much higher than test accuracy) and list two or three mitigations.

## Interview Takeaways

- Supervised vs unsupervised vs reinforcement learning, cold. Know one example of each.
- Training vs inference is a system design fault line. They have different costs, hardware, and scaling profiles.
- Never evaluate on training data. Never leak the test set.
- Overfitting has a clear symptom (train much better than test) and standard mitigations (more data, simpler model, regularization, early stopping).
- You do not need the math to talk AI/ML fluently. You need the shape of the idea and the right vocabulary.
