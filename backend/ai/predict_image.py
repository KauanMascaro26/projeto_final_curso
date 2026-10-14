
import argparse
import json
from pathlib import Path

import numpy as np
import tensorflow as tf
from tensorflow.keras.applications.mobilenet_v2 import (
    preprocess_input,
)
from tensorflow.keras.utils import load_img, img_to_array


BASE_DIR = Path(__file__).resolve().parent
MODEL_PATH = BASE_DIR / "models" / "waste_classifier.keras"
CLASSES_PATH = BASE_DIR / "models" / "class_names.json"

IMAGE_SIZE = (224, 224)


def load_classes():
    with open(CLASSES_PATH, "r", encoding="utf-8") as file:
        data = json.load(file)

    # Aceita tanto uma lista de classes quanto um objeto JSON.
    if isinstance(data, list):
        return data

    for key in ("class_names", "classes", "classes_order"):
        if key in data and isinstance(data[key], list):
            return data[key]

    raise ValueError(
        "Formato de classes.json não reconhecido. "
        "Verifique o arquivo class_names.json."
    )


def predict_image(image_path):
    if not MODEL_PATH.exists():
        raise FileNotFoundError(
            f"Modelo não encontrado: {MODEL_PATH}"
        )

    if not CLASSES_PATH.exists():
        raise FileNotFoundError(
            f"Arquivo de classes não encontrado: {CLASSES_PATH}"
        )

    image_path = Path(image_path)

    if not image_path.is_file():
        raise FileNotFoundError(
            f"Imagem não encontrada: {image_path}"
        )

    model = tf.keras.models.load_model(MODEL_PATH)
    classes = load_classes()

    image = load_img(
        image_path,
        target_size=IMAGE_SIZE,
        color_mode="rgb",
        interpolation="bilinear",
    )
    image_array = img_to_array(image)
    image_array = np.expand_dims(image_array, axis=0)
    image_array = preprocess_input(image_array)

    predictions = model.predict(image_array, verbose=0)[0]

    if len(predictions) != len(classes):
        raise ValueError(
            "A quantidade de classes não corresponde às saídas do modelo."
        )

    ranked = np.argsort(predictions)[::-1]

    print(f"\nImagem: {image_path.name}")
    print(f"Material previsto: {classes[ranked[0]]}")
    print(f"Confiança do modelo: {predictions[ranked[0]]:.2%}")

    print("\nTodas as previsões:")
    for index in ranked:
        print(f"  {classes[index]}: {predictions[index]:.2%}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Classifica uma imagem de resíduo."
    )
    parser.add_argument(
        "imagem",
        help="Caminho da imagem que será classificada.",
    )
    args = parser.parse_args()

    predict_image(args.imagem)
