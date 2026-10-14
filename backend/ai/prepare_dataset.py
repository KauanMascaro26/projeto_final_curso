"""Prepare TrashNet images for the initial four-class classifier.

Example:
  python backend/ai/prepare_dataset.py --source "C:\Users\kauan\Downloads\imagens"
"""
from __future__ import annotations

import argparse
import random
import shutil
from collections import Counter
from pathlib import Path

IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
CLASS_MAP = {
    "plastic": "plastic",
    "plastics": "plastic",
    "paper": "paper_cardboard",
    "cardboard": "paper_cardboard",
    "glass": "glass",
    "metal": "metal",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Organiza imagens do TrashNet em treino, validação e teste."
    )
    parser.add_argument("--source", required=True, type=Path,
                        help="Pasta extraída que contém as pastas das classes.")
    parser.add_argument(
        "--output", type=Path,
        default=Path(__file__).resolve().parent / "dataset",
        help="Pasta de saída (padrão: backend/ai/dataset).",
    )
    parser.add_argument("--seed", type=int, default=42,
                        help="Semente para reproduzir a divisão (padrão: 42).")
    parser.add_argument("--train", type=float, default=0.70,
                        help="Proporção de treino (padrão: 0.70).")
    parser.add_argument("--val", type=float, default=0.15,
                        help="Proporção de validação (padrão: 0.15).")
    return parser.parse_args()


def find_class_directories(source: Path) -> dict[str, list[Path]]:
    found: dict[str, list[Path]] = {name: [] for name in set(CLASS_MAP.values())}
    for directory in source.rglob("*"):
        if not directory.is_dir():
            continue
        mapped = CLASS_MAP.get(directory.name.strip().lower())
        if mapped:
            # Só considera pastas que tenham imagens diretamente dentro delas.
            if any(file.is_file() and file.suffix.lower() in IMAGE_EXTENSIONS
                   for file in directory.iterdir()):
                found[mapped].append(directory)
    return found


def main() -> None:
    args = parse_args()
    source = args.source.expanduser().resolve()
    output = args.output.expanduser().resolve()

    if not source.is_dir():
        raise SystemExit(f"ERRO: pasta de origem não encontrada: {source}")
    if args.train <= 0 or args.val <= 0 or args.train + args.val >= 1:
        raise SystemExit("ERRO: --train e --val devem ser positivos e sua soma menor que 1.")
    if output == source or source in output.parents:
        raise SystemExit(
            "ERRO: a pasta de saída não pode ser a origem nem ficar dentro dela."
        )

    discovered = find_class_directories(source)
    selected: dict[str, Path] = {}
    missing = []
    ambiguous = []

    for class_name, directories in discovered.items():
        if not directories:
            missing.append(class_name)
        elif len(directories) > 1:
            ambiguous.append((class_name, directories))
        else:
            selected[class_name] = directories[0]

    if ambiguous:
        print("Foram encontradas várias pastas para a mesma classe:")
        for class_name, directories in ambiguous:
            print(f"\n{class_name}:")
            for directory in directories:
                print(f"  {directory}")
        raise SystemExit(
            "\nUse --source apontando para uma única versão do dataset "
            "(por exemplo, dataset-resized), para não misturar cópias diferentes."
        )
    if missing:
        print("Aviso: não encontrei pastas para:", ", ".join(missing))
        print("Classes encontradas:", ", ".join(sorted(selected)))
    if not selected:
        raise SystemExit(
            "ERRO: nenhuma pasta de classe reconhecida. "
            "Confira se --source aponta para a pasta que contém plastic, paper, "
            "cardboard, glass e metal."
        )

    images_by_class: dict[str, list[Path]] = {}
    for class_name, directory in selected.items():
        images = sorted(
            file for file in directory.iterdir()
            if file.is_file() and file.suffix.lower() in IMAGE_EXTENSIONS
        )
        if images:
            images_by_class[class_name] = images

    if not images_by_class:
        raise SystemExit("ERRO: as pastas reconhecidas não contêm imagens suportadas.")

    # Não apaga dados anteriores automaticamente; isso evita perda acidental.
    if output.exists() and any(output.iterdir()):
        raise SystemExit(
            f"ERRO: a saída já existe e não está vazia: {output}\n"
            "Renomeie/remova essa pasta ou escolha outra com --output. "
            "O script não apaga resultados anteriores."
        )

    rng = random.Random(args.seed)
    totals: Counter[str] = Counter()
    output.mkdir(parents=True, exist_ok=True)

    for class_name, images in sorted(images_by_class.items()):
        rng.shuffle(images)
        count = len(images)
        train_count = int(count * args.train)
        val_count = int(count * args.val)

        # Com ao menos 3 imagens, tenta manter pelo menos uma em cada conjunto.
        if count >= 3:
            train_count = max(1, train_count)
            val_count = max(1, val_count)
            if train_count + val_count >= count:
                val_count = max(1, count - train_count - 1)
        train_images = images[:train_count]
        val_images = images[train_count:train_count + val_count]
        test_images = images[train_count + val_count:]

        for split, split_images in (
            ("train", train_images),
            ("val", val_images),
            ("test", test_images),
        ):
            destination = output / split / class_name
            destination.mkdir(parents=True, exist_ok=True)
            for index, image in enumerate(split_images, start=1):
                target = destination / f"{class_name}_{index:05d}{image.suffix.lower()}"
                shutil.copy2(image, target)
                totals[f"{split}/{class_name}"] += 1

    print(f"\nDataset preparado em: {output}")
    print(f"Semente: {args.seed}")
    print("\nQuantidade de imagens por conjunto:")
    for split in ("train", "val", "test"):
        split_total = sum(value for key, value in totals.items()
                          if key.startswith(f"{split}/"))
        print(f"  {split}: {split_total}")
        for class_name in sorted(images_by_class):
            print(f"    {class_name}: {totals[f'{split}/{class_name}']}")
    print(
        "\nRevise visualmente as pastas e os rótulos antes do treinamento. "
        "O script copia imagens; os arquivos de origem permanecem intactos."
    )


if __name__ == "__main__":
    main()
