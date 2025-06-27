:: Comando para baixar e instalar o programa git-sweep para limpeza de branchs: pip install git-sweep
:: Dicionário dos comandos:
:: cleanup: executa a limpeza dos branchs que foram feitos para o ambiente master
:: preview: faz uma prévia com todos os branchs que já foram mergiados para o branch master, comando não faz nenhuma alteração em seu repositório.
:: --master=develop: indica que o branch master passa a ser o branch develop para fins de execução do programa de limpeza.
:: --nofetch: indica para o programa pular o git fetch que é feito por padrão.
:: --skip=develop: indica que é para pular este branch passado como parãmetro.
:: --force: comando para não mostrar a mensagem "Excluir esses branchs? (s/n)" e começar a excluir os branhcs imediatamente.

@echo off
cls
set /p nome_branch=Informe o nome do branch da manutencao que sera verificado para fazer a limpeza, exemplo erp-5-10-1:   
echo A versao escolhida foi  '%nome_branch%'.

if "%nome_branch%" == "erp-5-10-1" (
  cd\
  cd "C:\ERP\5.10.1\gestao-empresarial-fontes"
  echo "C:\ERP\5.10.1\gestao-empresarial-fontes"
) else (
  cd\
  cd "C:\ERP\5.10.2\gestao-empresarial-fontes"
  echo "C:\ERP\5.10.2\gestao-empresarial-fontes"
)

set parametros=--master=%nome_branch% --skip=%nome_branch%-develop --force --nofetch
echo Os parametros definidos foram '%parametros%'.
echo Executando a limpeza no branch '%nome_branch%'.
git-sweep cleanup %parametros%

pause
set parametros=--master=%nome_branch%-develop --skip=%nome_branch% --force --nofetch
echo Os parametros definidos foram '%parametros%'.
echo Executando a limpeza no branch '%nome_branch%-develop'.
git-sweep cleanup %parametros%
