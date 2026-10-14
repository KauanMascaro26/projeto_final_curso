# IA de identificação de resíduos por imagem

O modelo ainda não foi treinado. Este diretório documenta o primeiro experimento visual do Descarte Inteligente.

## Escopo da primeira versão

Vamos começar com **quatro classes visuais**:

- `plastic`: plástico
- `paper_cardboard`: papel e papelão
- `glass`: vidro
- `metal`: metal

Eletrônicos ficam como possível expansão, depois de encontrarmos e avaliarmos imagens suficientes. Óleo de cozinha, orgânicos e rejeitos serão tratados inicialmente pela identificação por texto/busca, usando as orientações do banco de dados. Pilhas e baterias também ficam fora do primeiro modelo visual.

Essa divisão é intencional: é melhor entregar um classificador limitado e avaliado do que alegar que reconhece classes para as quais não temos dados suficientes.

## Estratégia do modelo

O baseline será **transfer learning com MobileNetV2 pré-treinada**, usando TensorFlow/Keras. Vamos reaproveitar os recursos visuais aprendidos no pré-treinamento e adaptar a camada de classificação às quatro classes.

A MobileNetV2 é uma candidata inicial, não uma garantia de desempenho. Vamos avaliar métricas por classe, matriz de confusão e comportamento com fotos diferentes das usadas no treino. A confiança do modelo não é garantia de acerto.

Fluxo previsto: dataset revisado → treinamento → avaliação → modelo e rótulos salvos → endpoint de inferência no FastAPI → integração com Flutter. A IA prevê uma classe; o backend usa essa classe para consultar as orientações de descarte no banco.

## Dataset inicial: TrashNet

Repositório original: https://github.com/garythung/trashnet

Antes de usar ou redistribuir imagens, confira a licença e as condições descritas no repositório. Baixe o dataset para a sua máquina; não envie todas as imagens para o GitHub do projeto.

O script `prepare_dataset.py` combina as pastas `paper` e `cardboard` em `paper_cardboard`, mantendo `plastic`, `glass` e `metal` separadas. A classe genérica `trash` fica fora do primeiro modelo, pois não representa de forma confiável nossa classe de rejeitos.

## Dataset preparado

A divisão inicial aproximada é 70% treino, 15% validação e 15% teste. A execução inicial gerou 2.390 imagens:

| Conjunto | Quantidade |
|---|---:|
| Treino | 1.671 |
| Validação | 357 |
| Teste | 362 |
| **Total** | **2.390** |

As imagens são copiadas para `backend/ai/dataset/`; as originais não são alteradas. O diretório do dataset é ignorado pelo Git.

## Treinamento local

Use um ambiente virtual separado para a IA, sem misturar as dependências com o backend da API. O TensorFlow atual oferece pacotes para Windows CPU; para esta configuração use Python 3.10, 3.11, 3.12 ou 3.13 de 64 bits. GPU NVIDIA nativa no Windows não é suportada nas versões modernas do TensorFlow; o primeiro treinamento pode rodar em CPU.

Na raiz do repositório, no PowerShell:

```powershell
python --version
py -0p
python -m venv backend/ai/.venv
backend/ai/.venv/Scripts/Activate.ps1
python -m pip install --upgrade pip
pip install -r backend/ai/requirements-ai.txt
python backend/ai/train_model.py
```

Se o Python padrão não for 3.10–3.13 de 64 bits, crie o ambiente com uma versão instalada explicitamente, por exemplo `py -3.12 -m venv backend/ai/.venv`. Se a ativação for bloqueada pela política do PowerShell, use o Python do ambiente diretamente:

```powershell
backend/ai/.venv/Scripts/python.exe -m pip install --upgrade pip
backend/ai/.venv/Scripts/python.exe -m pip install -r backend/ai/requirements-ai.txt
backend/ai/.venv/Scripts/python.exe backend/ai/train_model.py
```

O treinamento baixa os pesos pré-treinados do MobileNetV2 na primeira execução, então é necessária conexão com a internet. O primeiro experimento usa 224×224 pixels, batch de 32 e até 12 épocas; o treinamento pode levar alguns minutos ou mais, dependendo do computador.

O script salva localmente, em `backend/ai/models/`:

- `waste_classifier.keras`: melhor modelo conforme a perda de validação.
- `class_names.json`: ordem das classes usada pelo modelo.
- `metrics.json`: métricas do teste e matriz de confusão.

Esses arquivos são ignorados pelo Git. **Não considere o modelo pronto só porque o treinamento terminou**: confira a acurácia, as métricas por classe e a matriz de confusão, e teste fotos externas antes de integrar.

## Critérios antes de integrar

- Registrar origem, licença e quantidade de imagens por classe.
- Conferir visualmente os rótulos e o equilíbrio das classes.
- Não usar imagens de teste para ajustar o modelo.
- Avaliar precisão/recall por classe e matriz de confusão, não apenas acurácia geral.
- Prever uma resposta de baixa confiança/objeto não reconhecido.
- Testar com fotografias reais que não foram usadas no treinamento.

**Importante:** até o modelo ser treinado, avaliado e integrado, o aplicativo não deve afirmar que uma foto foi classificada por IA.
