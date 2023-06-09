# -*- coding: utf-8 -*-
"""PredictionScript.ipynb

Automatically generated by Colaboratory.

Original file is located at
    https://colab.research.google.com/drive/1JnX4Q5JvjTjPjtWu3wMOHYw0v-hZA3aW

Import dependencies
"""

from keras.models import load_model
import numpy as np
import tensorflow as tf
from PIL import Image

"""Prediction functions"""

# Generate a tensorflow tensor from an image path
def tensorFromPath(path):
  img = np.array(Image.open(path).resize((48, 48)))
  img = np.asarray(img)
  if img.shape == (48, 48, 3):
    tensor = tf.image.rgb_to_grayscale(img)
    tensor = tf.reshape(tensor, (1, 48, 48, 1))
  else:
    tensor = tf.reshape(img, (1, 48, 48, 1))
  return tensor

# Load the model from path
def loadModel(path):
  model = load_model(path)
  return model

# Return the correct label
def getLabel(result):
  labels = ["angry", "disgust", "fear", "happy", "neutral", "sad", "surprise"]
  largest = -99999
  index = 0
  for i, k in enumerate(result):
    if largest < k:
      largest = k
      index = i

  return ("Depressed" if labels[index]=="sad" else ("Not Depressed - Emotion: " + labels[index]))

# Run all functions given image path and model path
def runPrediction(ModelPath, ImagePath):
  m = loadModel(ModelPath)
  t = tensorFromPath(ImagePath)
  r = max(m.predict(t))

  return getLabel(r)

"""Prediction"""

mPath = input("Input your model path: ")
iPath = input("Input your image path: ")
print(runPrediction(mPath, iPath))