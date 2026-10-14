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

Depois de extrair o dataset, vamos mapear as pastas originais para estes nomes:

| Pasta de destino | Conteúdo esperado |
|---|---|
| `plastic` | plástico |
| `paper_cardboard` | papel e papelão |
| `glass` | vidro |
| `metal` | metal |

O TrashNet original costuma trazer as classes `plastic`, `paper`, `cardboard`, `glass`, `metal` e `trash`. Portanto, papel e papelão serão combinados em `paper_cardboard`; a classe genérica `trash` não entrará no primeiro modelo, pois não representa de forma confiável nossa classe de rejeitos.

## Organização local esperada

Mantenha o dataset fora do Git e organize uma cópia preparada neste formato:

```text
backend/ai/dataset/
  train/
    plastic/
    paper_cardboard/
    glass/
    metal/
  val/
    plastic/
    paper_cardboard/
    glass/
    metal/
  test/
    plastic/
    paper_cardboard/
    glass/
    metal/
```

Divisão inicial aproximada: 70% treino, 15% validação e 15% teste. A separação deve ser feita antes de aplicar aumentos artificiais de imagem; fotos duplicadas ou quase idênticas não podem aparecer em conjuntos diferentes.

## Critérios antes de integrar

- Registrar origem, licença e quantidade de imagens por classe.
- Conferir visualmente os rótulos e o equilíbrio das classes.
- Não usar imagens de teste para ajustar o modelo.
- Avaliar precisão/recall por classe e matriz de confusão, não apenas acurácia geral.
- Prever uma resposta de baixa confiança/objeto não reconhecido.
- Testar com fotografias reais que não foram usadas no treinamento.

**Importante:** até o modelo ser treinado, avaliado e integrado, o aplicativo não deve afirmar que uma foto foi classificada por IA.
