
import json
from pathlib import Path

import numpy as np
import tensorflow as tf

AI_DIR = Path(__file__).resolve().parent
MODEL_PATH = AI_DIR / "models" / "waste_classifier.keras"
CLASSES_PATH = AI_DIR / "models" / "class_names.json"
TEST_DIR = AI_DIR / "dataset" / "test"

with open(CLASSES_PATH, "r", encoding="utf-8") as file:
    classes = json.load(file)

model = tf.keras.models.load_model(MODEL_PATH)

test_ds = tf.keras.utils.image_dataset_from_directory(
    TEST_DIR,
    image_size=(224, 224),
    batch_size=32,
    label_mode="int",
    class_names=classes,
    shuffle=False,
    interpolation="bilinear",
)

loss, accuracy = model.evaluate(test_ds, verbose=1)

y_true = []
y_pred = []

for images, labels in test_ds:
    probabilities = model.predict(images, verbose=0)
    y_true.extend(labels.numpy().tolist())
    y_pred.extend(np.argmax(probabilities, axis=1).tolist())

matrix = tf.math.confusion_matrix(
    y_true, y_pred, num_classes=len(classes)
).numpy()

print("\nOrdem das classes:", classes)
print(f"Acurácia do modelo salvo: {accuracy:.4%}")
print(f"Perda: {loss:.4f}")
print("\nMatriz de confusão (linhas = real, colunas = prevista):")
print(matrix)

print("\nRecall por classe:")
for index, name in enumerate(classes):
    total = int(matrix[index].sum())
    correct = int(matrix[index, index])
    recall = correct / total if total else 0
    print(f"{name}: {recall:.2%} ({correct}/{total})")
