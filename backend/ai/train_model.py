"""Treina um baseline de classificação de resíduos com MobileNetV2.

Execute na raiz do repositório:
  python backend/ai/train_model.py
"""
from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path

import numpy as np
import tensorflow as tf

AI_DIR = Path(__file__).resolve().parent
DEFAULT_DATASET = AI_DIR / "dataset"
DEFAULT_OUTPUT = AI_DIR / "models"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Treina e avalia o baseline MobileNetV2 para quatro classes."
    )
    parser.add_argument("--dataset", type=Path, default=DEFAULT_DATASET)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--epochs", type=int, default=12)
    parser.add_argument("--batch-size", type=int, default=32)
    parser.add_argument("--image-size", type=int, default=224)
    parser.add_argument("--seed", type=int, default=42)
    return parser.parse_args()


def verify_dataset(dataset_dir: Path) -> list[str]:
    expected_splits = ("train", "val", "test")
    expected_classes = {"plastic", "paper_cardboard", "glass", "metal"}

    for split in expected_splits:
        split_dir = dataset_dir / split
        if not split_dir.is_dir():
            raise SystemExit(f"ERRO: conjunto não encontrado: {split_dir}")

    train_classes = {
        path.name for path in (dataset_dir / "train").iterdir() if path.is_dir()
    }
    if train_classes != expected_classes:
        raise SystemExit(
            "ERRO: as classes de treino não correspondem às quatro classes esperadas.\n"
            f"Esperadas: {sorted(expected_classes)}\n"
            f"Encontradas: {sorted(train_classes)}"
        )

    for split in expected_splits:
        for class_name in expected_classes:
            class_dir = dataset_dir / split / class_name
            if not class_dir.is_dir() or not any(class_dir.iterdir()):
                raise SystemExit(
                    f"ERRO: pasta ausente ou vazia: {class_dir}"
                )

    return sorted(expected_classes)


def count_training_images(train_dir: Path, class_names: list[str]) -> Counter[str]:
    valid_extensions = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
    return Counter({
        name: sum(
            1 for file in (train_dir / name).iterdir()
            if file.is_file() and file.suffix.lower() in valid_extensions
        )
        for name in class_names
    })


def main() -> None:
    args = parse_args()
    dataset_dir = args.dataset.expanduser().resolve()
    output_dir = args.output.expanduser().resolve()

    if args.epochs < 1 or args.batch_size < 1 or args.image_size < 32:
        raise SystemExit("ERRO: epochs, batch-size e image-size devem ser positivos.")
    class_names = verify_dataset(dataset_dir)
    tf.keras.utils.set_random_seed(args.seed)

    print(f"TensorFlow: {tf.__version__}")
    print(f"Dataset: {dataset_dir}")
    print(f"Classes: {class_names}")
    print("Carregando imagens...")

    train_ds = tf.keras.utils.image_dataset_from_directory(
        dataset_dir / "train",
        image_size=(args.image_size, args.image_size),
        batch_size=args.batch_size,
        label_mode="int",
        class_names=class_names,
        shuffle=True,
        seed=args.seed,
    )
    val_ds = tf.keras.utils.image_dataset_from_directory(
        dataset_dir / "val",
        image_size=(args.image_size, args.image_size),
        batch_size=args.batch_size,
        label_mode="int",
        class_names=class_names,
        shuffle=False,
    )
    test_ds = tf.keras.utils.image_dataset_from_directory(
        dataset_dir / "test",
        image_size=(args.image_size, args.image_size),
        batch_size=args.batch_size,
        label_mode="int",
        class_names=class_names,
        shuffle=False,
    )

    autotune = tf.data.AUTOTUNE
    train_ds = train_ds.prefetch(autotune)
    val_ds = val_ds.prefetch(autotune)
    test_ds = test_ds.prefetch(autotune)

    counts = count_training_images(dataset_dir / "train", class_names)
    total = sum(counts.values())
    class_weight = {
        index: total / (len(class_names) * max(counts[name], 1))
        for index, name in enumerate(class_names)
    }
    print("Imagens de treino por classe:", dict(counts))
    print("Pesos de classe:", {class_names[i]: round(w, 3) for i, w in class_weight.items()})

    augmentation = tf.keras.Sequential(
        [
            tf.keras.layers.RandomFlip("horizontal"),
            tf.keras.layers.RandomRotation(0.08),
            tf.keras.layers.RandomZoom(0.10),
        ],
        name="data_augmentation",
    )

    backbone = tf.keras.applications.MobileNetV2(
        input_shape=(args.image_size, args.image_size, 3),
        include_top=False,
        weights="imagenet",
    )
    backbone.trainable = False

    inputs = tf.keras.Input(shape=(args.image_size, args.image_size, 3))
    x = augmentation(inputs)
    x = tf.keras.applications.mobilenet_v2.preprocess_input(x)
    x = backbone(x, training=False)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.Dropout(0.25)(x)
    outputs = tf.keras.layers.Dense(len(class_names), activation="softmax")(x)
    model = tf.keras.Model(inputs, outputs, name="descarte_inteligente_mobilenetv2")

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-3),
        loss=tf.keras.losses.SparseCategoricalCrossentropy(),
        metrics=["accuracy"],
    )

    output_dir.mkdir(parents=True, exist_ok=True)
    model_path = output_dir / "waste_classifier.keras"
    callbacks = [
        tf.keras.callbacks.EarlyStopping(
            monitor="val_loss", patience=3, restore_best_weights=True
        ),
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss", factor=0.3, patience=2, min_lr=1e-6
        ),
        tf.keras.callbacks.ModelCheckpoint(
            filepath=str(model_path),
            monitor="val_loss",
            save_best_only=True,
        ),
    ]

    print("\nIniciando treinamento do classificador...")
    history = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=args.epochs,
        class_weight=class_weight,
        callbacks=callbacks,
    )

    # Recarrega o melhor checkpoint de validação antes de avaliar no teste.
    best_model = tf.keras.models.load_model(model_path)
    test_loss, test_accuracy = best_model.evaluate(test_ds, verbose=1)

    y_true = []
    y_pred = []
    for images, labels in test_ds:
        probabilities = best_model.predict(images, verbose=0)
        y_true.extend(labels.numpy().tolist())
        y_pred.extend(np.argmax(probabilities, axis=1).tolist())

    matrix = tf.math.confusion_matrix(
        y_true, y_pred, num_classes=len(class_names)
    ).numpy()
    per_class = {}
    for index, name in enumerate(class_names):
        true_positive = int(matrix[index, index])
        support = int(matrix[index].sum())
        predicted = int(matrix[:, index].sum())
        precision = true_positive / predicted if predicted else 0.0
        recall = true_positive / support if support else 0.0
        per_class[name] = {
            "precision": round(precision, 4),
            "recall": round(recall, 4),
            "support": support,
        }

    labels_path = output_dir / "class_names.json"
    labels_path.write_text(
        json.dumps(class_names, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    metrics = {
        "tensorflow_version": tf.__version__,
        "model": "MobileNetV2 transfer learning; backbone frozen",
        "image_size": args.image_size,
        "class_names": class_names,
        "test_loss": float(test_loss),
        "test_accuracy": float(test_accuracy),
        "per_class": per_class,
        "confusion_matrix": matrix.tolist(),
        "epochs_completed": len(history.history.get("loss", [])),
        "training_images_per_class": dict(counts),
    }
    metrics_path = output_dir / "metrics.json"
    metrics_path.write_text(
        json.dumps(metrics, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print("\nTreinamento concluído.")
    print(f"Modelo salvo em: {model_path}")
    print(f"Classes salvas em: {labels_path}")
    print(f"Métricas salvas em: {metrics_path}")
    print(f"Acurácia no teste: {test_accuracy:.4f}")
    print(f"Perda no teste: {test_loss:.4f}")
    print("Matriz de confusão (linhas = classe real, colunas = prevista):")
    print(matrix)
    print("Métricas por classe:")
    for name, values in per_class.items():
        print(
            f"  {name}: precision={values['precision']:.3f}, "
            f"recall={values['recall']:.3f}, suporte={values['support']}"
        )
    print(
        "\nA acurácia do teste não garante desempenho em fotos do mundo real. "
        "Revise erros e teste imagens independentes antes de integrar o modelo."
    )


if __name__ == "__main__":
    main()
