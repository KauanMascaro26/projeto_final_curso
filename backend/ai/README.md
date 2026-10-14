# IA de identificação de resíduos por imagem

Este diretório organiza a futura classificação de resíduos por imagem. **O modelo ainda não foi treinado**; os nomes abaixo são o contrato inicial entre o dataset, o backend e o aplicativo.

## Estratégia inicial do modelo

A abordagem escolhida para o primeiro experimento é **transfer learning com MobileNetV2 pré-treinada**, usando TensorFlow/Keras. Em vez de treinar toda a rede do zero, vamos reaproveitar os recursos visuais aprendidos no pré-treinamento e adaptar a camada de classificação às classes de resíduos do projeto.

A MobileNetV2 é uma candidata inicial, não uma garantia de desempenho. Depois de montar o dataset, vamos treinar um baseline e avaliar métricas por classe, matriz de confusão e comportamento com imagens fora das classes. Se os resultados forem insuficientes, poderemos comparar outra arquitetura.

O fluxo previsto é: dataset revisado → treinamento com transferência de aprendizado → avaliação → exportação do modelo e mapeamento de rótulos → endpoint de inferência no FastAPI → integração com Flutter. A IA prevê a classe; a API consulta as regras e orientações de descarte no banco de dados.

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

## Próximas etapas

1. Escolher e verificar fontes de imagens e respectivas licenças.
2. Montar um dataset inicial e conferir o balanceamento das classes.
3. Implementar o treinamento baseline com MobileNetV2 e avaliar os resultados.
4. Salvar modelo, mapeamento de rótulos e métricas de avaliação.
5. Implementar a inferência no FastAPI e validar tamanho/formato das imagens.
6. Integrar captura/galeria no Flutter e exibir classe, confiança, orientação do banco e opção de tentar novamente.
7. Testar com fotos reais não utilizadas no treinamento.

**Importante:** até o modelo treinado e avaliado ser integrado, a aplicação não deve afirmar que uma foto foi classificada por IA.
