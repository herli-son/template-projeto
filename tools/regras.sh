#!/usr/bin/env bash
# Confere as regras do projeto (CLAUDE.md): mensagem de commit, nome de branch
# e destino de Pull Request. Usado pelos hooks de .githooks/ e pela
# verificação automática de .github/workflows/regras.yml.
#
#   tools/regras.sh commit <arquivo-da-mensagem>
#   tools/regras.sh mensagem "<primeira linha>" ["<mensagem inteira>"]
#   tools/regras.sh branch <nome>
#   tools/regras.sh pr <branch-de-origem> <branch-de-destino>
#
# Sai com 0 se está dentro da regra e com 1 se não está, dizendo o motivo.

set -u

TIPOS='feat|fix|refactor|style|test|docs|build|perf|ci|revert'
# !#atividade - ?tipo da atividade - !type(?scope): !subject
LINHA="^#[0-9]+ - ([^:()-]+ - )?(${TIPOS})(\([^()]+\))?: [^ ].*$"

falha() {
  echo "regra quebrada: $1" >&2
  shift
  for linha in "$@"; do echo "  $linha" >&2; done
  echo "  (as regras estão em CLAUDE.md)" >&2
  exit 1
}

mensagem() {
  local primeira="$1" inteira="${2:-$1}"
  # Commits que o git ou o GitHub escrevem sozinhos.
  case "$primeira" in
    "Merge "*|"Initial commit") return 0 ;;
  esac
  if ! [[ "$primeira" =~ $LINHA ]]; then
    falha "a primeira linha do commit está fora do padrão" \
      "veio:     $primeira" \
      "esperado: #<n da issue> - <tipo da issue, opcional> - <type>(<scope, opcional>): <subject>" \
      "exemplo:  #12 - Feature - feat(pedidos): adicionar cálculo do frete" \
      "types:    ${TIPOS//|/, }"
  fi
  # Todo commit identifica a Feature: na primeira linha, ou no rodapé.
  if ! [[ "$primeira" =~ ^#[0-9]+\ -\ Feature\ -\  ]] && ! grep -Eq '^Feature: #[0-9]+$' <<<"$inteira"; then
    echo "aviso: o commit não diz a qual Feature pertence (rodapé \"Feature: #n\")." >&2
  fi
  return 0
}

branch() {
  local nome="$1"
  case "$nome" in
    main|develop) return 0 ;;
  esac
  if [[ "$nome" =~ ^feature/[0-9]+$ ]] \
    || [[ "$nome" =~ ^feature/user/[0-9]+-[0-9]+$ ]] \
    || [[ "$nome" =~ ^beta/[0-9]+\.[0-9]+\.[0-9]+$ ]] \
    || [[ "$nome" =~ ^hotfix/[0-9]+$ ]] \
    || [[ "$nome" =~ ^bugfix/[0-9]+$ ]]; then
    return 0
  fi
  falha "o nome da branch está fora do padrão" \
    "veio:     $nome" \
    "esperado: feature/<n>, feature/user/<n da user story>-<n da feature>," \
    "          beta/<x.y.z>, hotfix/<n do bug> ou bugfix/<n do bug>"
}

pr() {
  local origem="$1" destino="$2"
  branch "$origem"
  local ok=1
  if [[ "$origem" =~ ^feature/user/[0-9]+-([0-9]+)$ ]]; then
    # A User Story volta para a branch da Feature dela.
    [[ "$destino" == "feature/${BASH_REMATCH[1]}" ]] && ok=0
  elif [[ "$origem" =~ ^feature/[0-9]+$ ]]; then
    [[ "$destino" == "develop" ]] && ok=0
  elif [[ "$origem" =~ ^hotfix/ ]]; then
    [[ "$destino" == "main" ]] && ok=0
  elif [[ "$origem" =~ ^bugfix/ ]]; then
    { [[ "$destino" == "develop" ]] || [[ "$destino" =~ ^beta/ ]]; } && ok=0
  elif [[ "$origem" =~ ^beta/ ]]; then
    # A beta vai para a main quando está pronta, e leva cada correção à develop.
    { [[ "$destino" == "main" ]] || [[ "$destino" == "develop" ]]; } && ok=0
  elif [[ "$origem" == "main" ]]; then
    # Depois de um hotfix, a main volta para a develop.
    [[ "$destino" == "develop" ]] && ok=0
  fi
  if [[ $ok -ne 0 ]]; then
    falha "este Pull Request vai para a branch errada" \
      "veio:     $origem -> $destino" \
      "regra:    feature/user/<us>-<f> -> feature/<f>;  feature/<n> -> develop;" \
      "          bugfix/<n> -> develop ou beta/<v>;  hotfix/<n> -> main;" \
      "          beta/<v> -> main ou develop;  main -> develop"
  fi
  return 0
}

case "${1:-}" in
  commit)
    [[ -f "${2:-}" ]] || falha "arquivo da mensagem não encontrado: ${2:-}"
    # Sem as linhas de comentário que o git põe no editor.
    inteira="$(grep -v '^#[^0-9]' "$2" | grep -v '^#$' || true)"
    primeira="$(sed -n '/[^[:space:]]/{p;q;}' <<<"$inteira")"
    mensagem "$primeira" "$inteira"
    ;;
  mensagem) mensagem "${2:-}" "${3:-${2:-}}" ;;
  branch) branch "${2:-}" ;;
  pr) pr "${2:-}" "${3:-}" ;;
  *)
    echo "uso: $0 commit <arquivo> | mensagem <linha> [<inteira>] | branch <nome> | pr <origem> <destino>" >&2
    exit 2
    ;;
esac
