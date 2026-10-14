# IA de identificação de resíduos por imagem

Este diretório organiza a futura classificação de resíduos por imagem. **O modelo ainda não foi treinado**; os nomes abaixo são o contrato inicial entre o dataset, o backend e o aplicativo.

## Classes iniciais

| Rótulo técnico | Categoria apresentada no app | Exemplos |
|---|---|---|
| `plastic` | Plástico | garrafa PET, embalagem plástica |
| `paper_cardboard` | Papel | folha, jornal, caixa de papelão |
| `glass` | Vidro | garrafa, pote de vidro |
| `metal` | Metal | lata de alumínio, lata de aço |
| `electronics` | Eletrônico | cabo, carregador, pequeno aparelho |
| `batteries` | Pilhas e baterias | pilha AA, bateria portátil |
| `cooking_oil` | Óleo de cozinha | recipiente com óleo usado |
| `organic` | Orgânico | cascas e restos de alimentos |
| `reject` | Rejeito | material sem reciclagem viável, conforme orientação local |

As classes representam uma primeira versão. Antes de treinar, é preciso confirmar que cada classe possui imagens suficientes e visualmente distinguíveis. Se uma classe não tiver dados confiáveis, ela não deve ser simulada nem apresentada como reconhecida pelo modelo.

## Estrutura esperada do dataset

Organize imagens licenciadas ou coletadas com autorização nesta estrutura (não versionar imagens privadas ou muito pesadas sem avaliar Git LFS):

```text
dataset/
  train/
    plastic/
    paper_cardboard/
    glass/
    metal/
    electronics/
    batteries/
    cooking_oil/
    organic/
    reject/
  val/
    plastic/
    paper_cardboard/
    glass/
    metal/
    electronics/
    batteries/
    cooking_oil/
    organic/
    reject/
  test/
    plastic/
    paper_cardboard/
    glass/
    metal/
    electronics/
    batteries/
    cooking_oil/
    organic/
    reject/
```

- Separar imagens por objeto/captura antes da divisão, evitando que fotos quase idênticas apareçam em treino e teste.
- Começar com uma divisão aproximada de 70% treino, 15% validação e 15% teste.
- Buscar diversidade de iluminação, fundos, ângulos, tamanhos e estado do material.
- Não usar imagens de teste para ajustar o modelo.
- Registrar origem, licença e quantidade por classe.
- Avaliar precisão por classe e matriz de confusão; não confiar apenas na acurácia geral.
- Incluir uma forma de recusar imagens fora das classes ou com baixa confiança. A confiança do modelo não é garantia de acerto.

## Estratégia de implementação

1. Reunir e revisar as imagens e licenças.
2. Treinar e avaliar um classificador baseline.
3. Salvar modelo, mapeamento de rótulos e métricas de avaliação.
4. Implementar a inferência no FastAPI e validar tamanho/formato das imagens.
5. Integrar captura/galeria no Flutter e exibir classe, confiança, orientação do banco e opção de tentar novamente.
6. Testar com fotos reais não utilizadas no treinamento.

**Importante:** até o modelo treinado e avaliado ser integrado, a aplicação não deve afirmar que uma foto foi classificada por IA.
