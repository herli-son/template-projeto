# Template de projeto

Ponto de partida para um repositório novo, já com as regras de trabalho e a verificação automática delas:

- **Padrão de commits** baseado em Conventional Commits, com o número da issue na frente.
- **Git flow** com `main`, `develop`, betas, Features, User Stories, hotfix e bugfix.
- **Revisão de código antes de todo Pull Request.**
- **Issues só fecham quando o código chega na `main`.**

O texto completo das regras está em [`CLAUDE.md`](CLAUDE.md). O arquivo tem esse nome para o Claude Code lê-lo sozinho ao trabalhar no repositório; para pessoas, é o guia de contribuição.

## As regras em resumo

**Commit:**

```text
#<n da issue> - <tipo da issue, opcional> - <type>(<scope, opcional>): <subject no imperativo>

<corpo, opcional>

Feature: #<n da feature>
```

Types: `feat`, `fix`, `refactor`, `style`, `test`, `docs`, `build`, `perf`, `ci`, `revert`. Um só por commit.

**Branches:**

| Branch | Nome | Sai de | Volta para |
|---|---|---|---|
| Versão publicada | `main` | | |
| Desenvolvimento | `develop` | `main` | |
| Beta | `beta/<x.y.z>` | `develop` | `main` (e `develop`, a cada correção) |
| Feature | `feature/<n>` | `develop` | `develop` |
| User Story | `feature/user/<n da user story>-<n da feature>` | a branch da Feature | a branch da Feature |
| Hotfix | `hotfix/<n do bug>` | `main` | `main` |
| Bugfix | `bugfix/<n do bug>` | `develop` ou a beta | a mesma de onde saiu |

Toda integração entre branches é por Pull Request.

## O que vem no template

| Arquivo | Para que serve |
|---|---|
| `CLAUDE.md` | As regras, por extenso. |
| `tools/regras.sh` | Confere mensagem de commit, nome de branch e destino de PR. |
| `tools/testar-regras.sh` | Testes do script acima. |
| `.githooks/commit-msg`, `.githooks/pre-push` | Recusam o commit e o push fora do padrão, na sua máquina. |
| `.github/workflows/regras.yml` | Confere o mesmo em cada Pull Request. |
| `.github/pull_request_template.md` | Modelo de Pull Request. |
| `.github/ISSUE_TEMPLATE/` | Modelos de Feature, User Story e Bug. |
| `tools/criar-etiquetas.sh` | Cria as etiquetas que as regras usam. |

## Como usar

1. No GitHub, **Use this template** > **Create a new repository**. Marque **Include all branches**, para a `develop` vir junto.
2. Clone o repositório novo e ligue os hooks, uma vez por clone:

   ```bash
   git config core.hooksPath .githooks
   ```

3. Troque este README pelo do seu projeto e ajuste o título de `CLAUDE.md`.

## Depois de criar o repositório

O GitHub não copia etiquetas nem proteção de branch de um template. Faça uma vez:

1. **Etiquetas:** `tools/criar-etiquetas.sh` (precisa do [`gh`](https://cli.github.com/) autenticado).
2. **Proteção da `main` e da `develop`** (Settings > Branches, ou Rules > Rulesets):
   - exigir Pull Request antes do merge;
   - exigir a verificação **Regras do projeto / regras**;
   - impedir que as duas sejam apagadas.
3. **Apagar a branch depois do merge:** Settings > General > *Automatically delete head branches*. As regras pedem que as branches de User Story, Feature, hotfix e bugfix sejam apagadas depois do merge.

## O que a verificação automática cobre

- A primeira linha de cada commit (os "Merge ..." do git e do GitHub ficam de fora).
- O nome da branch.
- A branch de destino do Pull Request: por exemplo, `feature/user/23-12` só pode ir para `feature/12`, e a `main` só recebe beta ou hotfix.

Não cobre, e fica com as pessoas: o `subject` no imperativo, um commit por intenção, a revisão antes do PR e as etiquetas das issues. Falta do rodapé `Feature: #n` gera só um aviso.

## Mudar as regras

Edite `CLAUDE.md` e `tools/regras.sh` juntos e rode `tools/testar-regras.sh`.
