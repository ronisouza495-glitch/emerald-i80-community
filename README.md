# Emerald i80 — Kit comunitário

Portal, automação e documentação para executar localmente um servidor Emerald i80 compatível com WoW 3.3.5a build 12340 e permitir acesso privado por Tailscale.

## ⬇ Download do instalador

**[CLIQUE AQUI PARA BAIXAR O ÚNICO BAT](https://github.com/ronisouza495-glitch/emerald-i80-community/releases/download/v1.1.0/INSTALAR_E_ABRIR_EMERALD.bat)**

Depois de baixar, abra `INSTALAR_E_ABRIR_EMERALD.bat`. Na primeira execução ele baixa, verifica, instala e inicia o servidor; nas próximas, apenas abre o que já foi instalado.

> Este repositório não distribui o cliente World of Warcraft, mapas, DBCs, VMAPs, MMAPs, executáveis do servidor, bancos de dados, MPQs ou outros arquivos de terceiros. Use o kit somente com arquivos que você tenha autorização para utilizar.

## O que está incluído

- site responsivo para os jogadores;
- instalador/inicializador portátil de um único BAT;
- download do runtime com verificação SHA-256 e instalação persistente;
- detecção e instalação assinada do Microsoft Visual C++ 2013 x64 quando `MSVCR120.dll` estiver ausente;
- importação local sem alterar o repack original;
- detecção automática do IP Tailscale;
- backup automático do banco `auth` antes de alterar o realm;
- atualização automática de `auth.realmlist`;
- criação do realmlist que deve ser enviado aos jogadores;
- instruções para Windows e Android/Winlator;
- configuração pronta para Vercel, GitHub Pages e hospedagem estática comum.

## Início rápido para o dono do servidor

1. Use o botão de download acima para baixar `INSTALAR_E_ABRIR_EMERALD.bat`.
2. Execute o BAT. Ele baixa o runtime, verifica o SHA-256 e instala em `%LOCALAPPDATA%\EmeraldI80`.
3. Na primeira execução, aguarde o download verificado do pacote completo do servidor.
4. Aguarde a extração, a criação do banco limpo e a validação de MySQL, AuthServer e WorldServer.
5. Nas execuções seguintes, abra o mesmo BAT; o download e a importação não serão repetidos.

O pacote não contém logs, backups, banco em uso, contas, personagens, binlogs ou símbolos de depuração. Veja [a documentação completa](docs/INSTALADOR-PORTATIL.md).

## Para o jogador

1. Instale o Tailscale no Windows ou Android.
2. Entre em uma conta própria.
3. Aceite o convite enviado pelo dono do servidor.
4. Deixe o Tailscale conectado.
5. No arquivo `Data/enUS/realmlist.wtf` — ou `enGB`/`ptBR` — use `set realmlist 100.x.y.z` com o IP informado.
6. Abra `Wow.exe` diretamente.

## Publicar o site no Vercel

O site está em `site/` e não exige instalação nem compilação.

### Pela interface do Vercel

1. Entre em [vercel.com](https://vercel.com/).
2. Escolha **Add New → Project**.
3. Importe este repositório do GitHub.
4. Defina **Root Directory** como `site`.
5. Escolha **Framework Preset: Other**.
6. Não informe Build Command.
7. Publique.

### GitHub Pages

O workflow incluído em `.github/workflows/pages.yml` publica a pasta `site/`. No repositório, abra **Settings → Pages** e selecione **GitHub Actions** como fonte.

## Limitação importante

Vercel e GitHub Pages hospedam o portal, não o servidor WoW. O protocolo do jogo usa TCP nas portas 3724 e 8085. O PC anfitrião deve permanecer ligado, com Tailscale, MySQL, AuthServer e WorldServer ativos.

## Segurança

- Nunca publique `configuracao-servidor.cmd`.
- Nunca publique `_Server/mysql/data`, pois contém contas e personagens.
- Nunca publique backups ou logs.
- O Release contém somente scripts, documentação e metadados do runtime; arquivos de terceiros são importados localmente.
- Compartilhe somente a máquina do servidor no Tailscale.
- Revogue o compartilhamento quando uma pessoa não precisar mais do acesso.

## Estrutura

```text
emerald-i80-community/
├── .github/workflows/pages.yml
├── INSTALAR_E_ABRIR_EMERALD.bat
├── release/
│   ├── LEIA-ME.txt
│   └── runtime-manifest.txt
├── servidor/
│   ├── ABRIR_EMERALD_ONLINE.bat
│   └── configuracao-servidor.exemplo.cmd
├── site/
│   ├── index.html
│   ├── styles.css
│   ├── app.js
│   └── vercel.json
├── docs/
│   ├── INSTALADOR-PORTATIL.md
│   ├── JOGADOR-PC-E-WINLATOR.md
│   └── PUBLICAR-SITE.md
├── .gitignore
├── LICENSE
└── README.md
```

## Licença

Os scripts, o site e a documentação deste kit são fornecidos sob a licença MIT. Essa licença não se aplica a arquivos do jogo, repacks, bancos de dados ou componentes de terceiros.
