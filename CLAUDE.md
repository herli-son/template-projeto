# Instruções do projeto

## Padrão de commits (obrigatório)

Todo commit deste repositório segue o padrão abaixo, baseado em Conventional Commits. Ele foi adaptado do padrão do time (Azure Boards) para o GitHub: o prefixo `AB#n` virou `#n`, onde `n` é o número da issue no GitHub.

### Estrutura

```text
!#activity - ?activity_type - !type(?scope): !subject

<?body>

<?footer>
```

- `!` = obrigatório; `?` = opcional.
- `#activity`: número da issue principal do commit (normalmente uma Feature ou um Bug). Obrigatório. O GitHub só cria o vínculo depois do `push`.
- `activity_type`: tipo da issue principal, por exemplo `Feature` ou `Bug`. Opcional.
- `type`: obrigatório, um só por commit (lista abaixo).
- `scope`: opcional, recomendado quando ajuda a dizer onde a mudança aconteceu. Vários escopos podem ser separados por `/`, `\` ou `,`.
- `subject`: obrigatório, breve, claro e **no imperativo** (teste: "Se aplicado, este commit vai [subject]").

### Atividades extras

Uma única atividade principal na primeira linha. Atividades adicionais vão abaixo da mensagem principal, no corpo ou no rodapé, uma por linha, no formato `#n`. Elas não substituem a principal.

```text
#12 - Feature - feat(pedidos): adicionar cálculo do frete

#15
#18
```

### Tipos

| Tipo | Uso |
|---|---|
| `feat` | Nova funcionalidade |
| `fix` | Correção de bug |
| `refactor` | Refatoração sem mudar regra de negócio |
| `style` | Formatação ou visual, sem mudar comportamento |
| `test` | Criação ou manutenção de testes |
| `docs` | Documentação |
| `build` | Build ou dependências |
| `perf` | Performance |
| `ci` | Integração contínua |
| `revert` | Reverter commit anterior |

O tipo `promote` (CherryFlow) não se aplica a este projeto.

### Exemplos

```bash
git commit -m "#1 - Feature - docs: adicionar README do projeto"
git commit -m "#7 - Feature - feat(pedidos): implementar cancelamento"
git commit -m "#9 - Bug - fix(pagamento): corrigir arredondamento do total"
git commit -m "#10 - test(pedidos): adicionar testes de cancelamento"
```

### Número da feature no commit

Todo commit precisa identificar a feature a que pertence. Se a atividade principal não for a própria feature (por exemplo, uma User Story ou um Bug), inclua o número da feature no fim da mensagem, no rodapé, no formato `Feature: #n`.

```text
#23 - feat(pagamento): adicionar pagamento por boleto

Feature: #12
```

### Regras práticas

- Um `type` por commit; se estiver difícil escolher um, o commit está grande demais e deve ser dividido.
- `#activity` e `type` são obrigatórios.
- Prefira commits pequenos e com responsabilidade única.
- Linhas de atribuição exigidas pela ferramenta (por exemplo `Co-Authored-By`) vão no rodapé e não alteram a primeira linha.

### Checklist antes de commitar

- [ ] O `type` está correto.
- [ ] O `#activity` foi informado corretamente.
- [ ] Atividades extras estão abaixo da mensagem principal, no formato `#n`.
- [ ] O `subject` está no imperativo.
- [ ] A mensagem descreve uma única intenção.
- [ ] O `scope` foi adicionado quando ajuda a dar contexto.
- [ ] O commit está pequeno o suficiente para ser entendido isoladamente.

## Estratégia de branches (git flow)

Hierarquia: `main` → `develop` → `feature` → `user`. As betas são branches filhas da `develop`.

| Branch | Nome | Sai de | Volta para | Papel |
|---|---|---|---|---|
| `main` | `main` | | | Versão publicada: só recebe versões prontas para uso (de uma beta ou de um hotfix) |
| `develop` | `develop` | `main` | | Desenvolvimento: integra as Features; as betas saem dela |
| Beta | `beta/[versão]` | `develop` | `main` (e a `develop`, por PR, a cada correção) | Versão em teste, congelada para o teste não travar a `develop` |
| Feature | `feature/[n° da feature]` | `develop` | `develop` | Desenvolvimento de uma Feature; uma Feature pode ter várias User Stories |
| User Story | `feature/user/[n° da user story]-[n° da feature]` | a branch da sua Feature | a branch da sua Feature | Onde as Tasks da User Story são desenvolvidas |
| Hotfix | `hotfix/[n° do bug]` | `main` | `main` | Bug encontrado na `main` |
| Bugfix | `bugfix/[n° do bug]` | `develop` ou a beta | a mesma branch de onde saiu | Bug encontrado na `develop` ou numa beta |

Exemplos: `feature/12`, `feature/user/23-12`, `beta/0.1.0`, `hotfix/40`, `bugfix/41`.

Regras:

- `main` e `develop` **nunca** são deletadas.
- As Tasks não têm branch própria: são feitas na branch da sua User Story.
- Depois do merge da User Story na Feature, a branch da User Story é deletada.
- Depois do merge da Feature na `develop`, a branch da Feature é deletada.
- Bugs são resolvidos a partir da branch onde foram encontrados.
- **Hotfix:** sai da `main`. Depois do merge na `main`, delete a branch e faça merge da `main` na `develop`.
- **Bugfix:** sai da `develop` ou da beta em que o bug foi achado e volta para ela. Depois do merge, delete a branch.
- **Beta:** sai da `develop` quando uma beta vai ser gerada. Correções de bugs achados no teste entram por `bugfix/[n° do bug]` (ver Bugfix). Depois de cada correção, um PR da beta para a `develop` leva a correção, para o bug não voltar na próxima beta. Quando estiver pronta para uso, a beta vai direto para a `main`. É deletada depois de chegar na `main` ou quando uma beta mais nova a substituir.
- **Versão da beta:** `0.y.z`; `y` sobe a cada beta nova e `z` a cada correção na mesma beta.
- Toda integração entre branches é feita por Pull Request.

## Revisão antes do PR

- Antes de abrir qualquer Pull Request, a mudança passa por uma revisão de código.
- Os achados da revisão são corrigidos antes de abrir o PR.
- Cada commit da branch precisa passar nos testes sozinho.

## Publicação e fechamento de issues

- Quando uma issue fica pronta (pelo merge de uma Feature ou de um bugfix na `develop`, ou de um bugfix numa beta), ela **continua aberta** e recebe a etiqueta `aguardando publicação`.
- As issues com essa etiqueta só fecham quando o código chega na `main`, ou seja, numa versão publicada: o PR da beta para a `main` traz uma linha `Closes #n` para cada issue com a etiqueta cujo código está na beta (inclusive os bugs corrigidos nela), e o GitHub as fecha no merge.
- PRs para branches de Feature, para a `develop` ou para uma beta não fecham issues.

## Verificação automática

- `tools/regras.sh` confere a mensagem de commit, o nome da branch e o destino do Pull Request.
- Os hooks de `.githooks/` recusam, na máquina de quem trabalha, o commit e o push fora do padrão. Ligar uma vez por clone: `git config core.hooksPath .githooks`.
- A verificação "Regras do projeto" (`.github/workflows/regras.yml`) confere o mesmo em cada Pull Request.
- Commits de merge escritos pelo git ou pelo GitHub ("Merge ...") ficam fora da regra da primeira linha.

Referência: [Conventional Commits](https://www.conventionalcommits.org/pt-br/v1.0.0/)
