# Instalador e inicializador portátil

`INSTALAR_E_ABRIR_EMERALD.bat` é o único arquivo que o administrador precisa baixar e executar.

Na primeira execução, ele:

1. baixa o runtime correspondente do GitHub Release;
2. confere o SHA-256 fixado dentro do próprio BAT;
3. extrai o runtime na instalação persistente;
4. baixa o pacote completo do servidor pelo GitHub Release;
5. confere também o SHA-256 do pacote antes da extração;
6. extrai o pacote limpo, sem contas, personagens, logs, backups ou binlogs;
7. cria um banco limpo, uma senha local aleatória e configura os servidores;
8. aguarda o MySQL responder na porta 3306 **e** validar a autenticação;
9. inicia AuthServer e WorldServer, confirmando que os processos permaneceram ativos.

Nas execuções seguintes, o download e a importação são ignorados quando os marcadores e a versão instalada conferem.

## Onde ficam os arquivos

- instalação persistente: `D:\EmeraldI80` quando a unidade `D:` estiver disponível; caso contrário, `%LOCALAPPDATA%\EmeraldI80`;
- dados do servidor: `D:\EmeraldI80\server` quando `D:` existir;
- segredo local: `D:\EmeraldI80\state\local-secrets.cmd` quando `D:` existir;
- logs do core: `D:\EmeraldI80\server\Logs` quando `D:` existir.

## O que não é publicado

O Release não inclui cliente WoW, contas, personagens, logs, backups, binlogs, tokens, IPs pessoais ou o banco em uso. A licença MIT do repositório cobre somente os scripts, o site e a documentação do kit comunitário.

## Verificação independente

Depois do download do ZIP do runtime:

```powershell
certutil -hashfile .\emerald-i80-runtime-v1.1.0.zip SHA256
```

O resultado deve ser idêntico ao valor `PAYLOAD_SHA256` dentro de `INSTALAR_E_ABRIR_EMERALD.bat` e ao arquivo `SHA256SUMS.txt` anexado ao Release.
