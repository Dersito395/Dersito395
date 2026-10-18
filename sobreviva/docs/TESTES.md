# Testes

## Automatizados

```bash
cd app && flutter test          # 43 testes
cd server && npm test           # 10 testes
cd app && SCREENSHOTS=1 flutter test test/screenshots/   # gera 16 capturas em app/build/screenshots/
```

| Arquivo | Cobre |
|---|---|
| `app/test/search_engine_test.dart` | normalização, consultas da especificação, sinônimos, correção de digitação, filtros, autocompletar, relacionados |
| `app/test/library_db_test.dart` | instalação do pacote essencial, integridade dos artigos (fonte, cuidados, etapas), atualização preservando dados do usuário, sem rebaixamento, **rollback de importação com erro**, formato futuro |
| `app/test/package_service_test.dart` | manifesto real, instalação da biblioteca completa, **pacote adulterado**, download truncado, cancelamento, falta de espaço, exigência de HTTPS |
| `app/test/user_db_test.dart` | favoritos, notas, histórico, preferências, exportação/importação, planejador de mochila |
| `app/test/widget_test.dart` | tela inicial (busca, indicador offline, 5 abas), pesquisa → artigo → favorito, guia de emergência com 5 seções, planejador → checklist, modo externo persistido |
| `server/test/server.test.js` | scrypt, manifesto e pacotes com SHA-256/ETag, travessia de caminho, login/CSRF/permissões, bloqueio de tentativas, fluxo editorial completo com revisão técnica e versionamento, separação editor/revisor, validação bloqueando envio, upload de mídia, publicação em modo estrito |

Também foi executado um teste de ponta a ponta no navegador (Chromium/Playwright) do painel: editora edita e
envia → administrador aprova e publica → nova versão da biblioteca é gerada e servida no manifesto.

## Roteiro em dispositivos físicos (Etapa 7)

Ainda **não executado** (requer aparelhos). Recomendado: 1 Android de entrada (Android 8–10, 2–3 GB RAM),
1 Android recente, 1 iPhone com iOS atual. Registrar modelo, sistema, versão do app e resultado de cada item.

| # | Critério de aceitação | Passos | Esperado |
|---|---|---|---|
| 1 | Instala e abre | instalar APK/TestFlight; abrir | splash e tela inicial em < 3 s |
| 2 | Primeiro acesso em modo avião | apagar dados do app; ativar modo avião; abrir | biblioteca com 37 artigos, "Offline • biblioteca disponível" |
| 3 | Pesquisa offline | em modo avião, pesquisar as 5 consultas da especificação | resultado correto em 1º lugar (ver PESQUISA.md) |
| 4 | Imagens offline | abrir "Como montar um abrigo…" e "Como utilizar uma bússola…" | diagramas visíveis, zoom ao tocar |
| 5 | Sem login | percorrer as 5 abas | nenhuma tela pede conta |
| 6 | Persistência | favoritar 2 artigos, criar nota e checklist; forçar fechamento; reabrir | tudo mantido |
| 7 | Atualização sem perda | com servidor de teste, baixar "Biblioteca completa"; publicar v2; atualizar | artigos novos aparecem; favoritos/notas intactos |
| 8 | Falha de atualização | iniciar download e ativar modo avião no meio; e cancelar outro | mensagem de erro; biblioteca anterior intacta |
| 9 | Fontes reais | abrir 3 artigos e conferir os links das fontes em um navegador | links válidos |
| 10 | Sem APIs externas | bloquear rede (firewall) e usar todas as funções | tudo funciona, exceto baixar pacotes |
| 11 | Responsividade | tela pequena (≤ 5"), tablet, fonte do sistema no máximo, modo externo | sem cortes/sobreposições; texto legível |
| 12 | Ligar emergência | tocar 192 na Central | discador abre com 192 (não completar a chamada) |
| 13 | Bateria | 30 min de leitura com economia de bateria ligada | fundo preto, sem animações, consumo menor que o modo normal |
| 14 | Leitor de tela | TalkBack/VoiceOver em busca, artigo e emergências | botões e imagens com rótulos |
| 15 | Compartilhar/exportar | compartilhar artigo (texto) e exportar anotações (JSON); importar em outro aparelho | conteúdo íntegro |
