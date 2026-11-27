#!/usr/bin/env bash
# Testes de tools/regras.sh. Rode depois de mexer nas regras:
#   tools/testar-regras.sh

cd "$(dirname "$0")/.." || exit 1
falhas=0

espera() { # espera <0|1> <descrição> <comando...>
  local esperado="$1" descricao="$2"
  shift 2
  "$@" >/dev/null 2>&1
  local veio=$?
  if [[ $veio -ne $esperado ]]; then
    echo "FALHOU: $descricao (esperado $esperado, veio $veio)"
    falhas=$((falhas + 1))
  fi
}

R=tools/regras.sh

# Mensagens de commit.
espera 0 "commit completo" $R mensagem "AB#12 - Feature - feat(pedidos): adicionar cálculo do frete"
espera 0 "sem tipo da atividade" $R mensagem "AB#10 - test(pedidos): adicionar testes de cancelamento"
espera 0 "sem escopo" $R mensagem "AB#1 - Feature - docs: adicionar README do projeto"
espera 0 "vários escopos" $R mensagem "AB#7 - Bug - fix(api/rede, tela): corrigir o envio"
espera 0 "tipo da atividade com espaço" $R mensagem "AB#7 - User Story - feat: adicionar a tela"
espera 0 "merge do git" $R mensagem "Merge pull request #3 from x/feature/1"
espera 0 "merge de branch" $R mensagem "Merge branch 'develop' into feature/1"
espera 1 "sem o work item" $R mensagem "feat(pedidos): adicionar cálculo do frete"
espera 1 "type desconhecido" $R mensagem "AB#12 - Feature - feature(pedidos): adicionar"
espera 1 "promote não se aplica" $R mensagem "AB#12 - promote: levar para a main"
espera 1 "sem subject" $R mensagem "AB#12 - feat(pedidos): "
espera 1 "sem os dois pontos" $R mensagem "AB#12 - feat(pedidos) adicionar"
espera 1 "work item sem número" $R mensagem "AB#abc - feat: adicionar"
espera 1 "prefixo do GitHub (#n) em vez de AB#n" $R mensagem "#12 - Feature - feat(pedidos): adicionar cálculo do frete"
espera 1 "prefixo em minúsculas" $R mensagem "ab#12 - feat: adicionar"
espera 1 "escopo vazio" $R mensagem "AB#12 - feat(): adicionar"
espera 1 "dois types" $R mensagem "AB#12 - feat/fix: adicionar e corrigir"
espera 1 "mensagem vazia" $R mensagem ""

# O arquivo de mensagem do git, com comentários e rodapé.
tmp="$(mktemp)"
printf 'AB#23 - feat(pagamento): adicionar boleto\n\nCorpo.\n\nFeature: AB#12\n# Please enter the commit message\n#\n' >"$tmp"
espera 0 "arquivo com rodapé e comentários do git" $R commit "$tmp"
printf '\n\nAB#23 - feat(pagamento): adicionar boleto\n' >"$tmp"
espera 0 "linhas em branco antes da primeira linha" $R commit "$tmp"
printf 'adicionar bloqueio\n\nAB#23 - feat: isto é corpo, não a primeira linha\n' >"$tmp"
espera 1 "padrão só no corpo" $R commit "$tmp"
espera 1 "arquivo que não existe" $R commit /nao/existe
# O formato antigo (#n) num arquivo de mensagem não é tratado como comentário
# do git: é recusado, mesmo com uma linha válida depois.
printf '#12 - Feature - feat: formato antigo\n' >"$tmp"
espera 1 "formato antigo sozinho no arquivo" $R commit "$tmp"
printf '#12 - Feature - feat: formato antigo\n\nAB#12 - Feature - feat: válida, mas no corpo\n' >"$tmp"
espera 1 "formato antigo na primeira linha e válido no corpo" $R commit "$tmp"
erro="$($R commit "$tmp" 2>&1)"
[[ "$erro" == *"veio:     #12 - Feature - feat: formato antigo"* ]] || { echo "FALHOU: o erro não mostra a linha escrita"; falhas=$((falhas + 1)); }
# O diff de "git commit -v" (depois da tesoura) não entra na mensagem.
printf 'AB#23 - feat: adicionar\n\nFeature: AB#12\n# ------------------------ >8 ------------------------\n# Do not modify\ndiff --git a/x b/x\n+#99 - linha do diff\n' >"$tmp"
espera 0 "arquivo com o diff do commit -v" $R commit "$tmp"
rm -f "$tmp"

# O aviso do rodapé da Feature (não muda a saída, só avisa).
aviso() { $R mensagem "$1" "$2" 2>&1 >/dev/null | grep -c "não diz a qual Feature"; }
confere_aviso() { # confere_aviso <0|1> <descrição> <primeira linha> <mensagem inteira>
  local veio
  veio="$(aviso "$3" "$4")"
  if [[ "$veio" -ne "$1" ]]; then
    echo "FALHOU: $2 (esperado $1 aviso, veio $veio)"
    falhas=$((falhas + 1))
  fi
}
confere_aviso 0 "a própria Feature na primeira linha" "AB#12 - Feature - feat: x" "AB#12 - Feature - feat: x"
confere_aviso 0 "rodapé Feature: AB#n" "AB#23 - feat: x" $'AB#23 - feat: x\n\nFeature: AB#12'
confere_aviso 0 "rodapé com espaço ou CR no fim" "AB#23 - feat: x" $'AB#23 - feat: x\n\nFeature: AB#12 \r'
confere_aviso 1 "sem rodapé" "AB#23 - feat: x" "AB#23 - feat: x"
confere_aviso 1 "rodapé no formato antigo (#n)" "AB#23 - feat: x" $'AB#23 - feat: x\n\nFeature: #12'

# Nomes de branch.
for b in main develop feature/12 feature/user/23-12 beta/0.1.0 hotfix/40 bugfix/41; do
  espera 0 "branch $b" $R branch "$b"
done
for b in feature/login feature/user/23 feature/user/23-x beta/0.1 beta/v0.1.0 hotfix/ bugfix/abc minha-branch Feature/12 feature/12/extra release/1.0.0; do
  espera 1 "branch $b" $R branch "$b"
done

# Destino dos Pull Requests.
espera 0 "user story -> a feature dela" $R pr feature/user/23-12 feature/12
espera 1 "user story -> outra feature" $R pr feature/user/23-12 feature/13
espera 1 "user story -> develop" $R pr feature/user/23-12 develop
espera 0 "feature -> develop" $R pr feature/12 develop
espera 1 "feature -> main" $R pr feature/12 main
espera 0 "hotfix -> main" $R pr hotfix/40 main
espera 1 "hotfix -> develop" $R pr hotfix/40 develop
espera 0 "bugfix -> develop" $R pr bugfix/41 develop
espera 0 "bugfix -> beta" $R pr bugfix/41 beta/0.1.0
espera 1 "bugfix -> main" $R pr bugfix/41 main
espera 0 "beta -> main" $R pr beta/0.1.0 main
espera 0 "beta -> develop" $R pr beta/0.1.0 develop
espera 1 "beta -> feature" $R pr beta/0.1.0 feature/12
espera 0 "main -> develop (depois de hotfix)" $R pr main develop
espera 1 "develop -> main" $R pr develop main
espera 1 "branch fora do padrão" $R pr minha-branch develop

if [[ $falhas -eq 0 ]]; then
  echo "regras: todos os testes passaram"
else
  echo "regras: $falhas teste(s) falharam"
  exit 1
fi
