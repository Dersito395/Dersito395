# Pacotes e atualizações

## Pacotes

Definidos em `content/packages.json` por regras de seleção:

| Pacote | Seleção | Instalação |
|---|---|---|
| Biblioteca essencial | artigos `essential: true` | **embarcada no app** (modo avião desde o 1º acesso) |
| Manual de primeiros socorros | categoria primeiros-socorros | download |
| Sobrevivência em mata | natureza, abrigos, fogo + ambiente mata | download |
| Emergências urbanas | emergências urbanas, planejamento, comunicação | download |
| Navegação e mapas | orientação | download |
| Guias ilustrados | artigos com imagens | download |
| Biblioteca completa | todos os publicados | download |

Todos os pacotes levam também categorias, fontes usadas, sinônimos, números e guias de emergência (pequenos).

## Formato

`manifest.json`:

```json
{ "format": 1, "library_version": 2, "generated_at": "…",
  "packages": [{ "id": "biblioteca-completa", "title": "…", "description": "…", "version": 2,
                 "released_at": "2026-10-18", "bundled": false, "url": "packages/biblioteca-completa-v2.json",
                 "size_bytes": 219844, "sha256": "…", "article_count": 39, "media_count": 23, "format": 1 }] }
```

Pacote: `{ format, package{id,title,version,…}, categories, sources, synonyms, numbers, emergencies, articles,
media[{file, mime, sha256, size, credit, license, data(base64)}] }`. A versão embarcada no app não traz `data`
(as imagens vão como assets).

## Garantias do cliente (`app/lib/services/package_service.dart`)

| Situação | Comportamento |
|---|---|
| Sem servidor configurado / sem rede | biblioteca local funciona normalmente; tela mostra o motivo |
| HTTP fora da rede local | recusado (HTTPS obrigatório) |
| Espaço livre < 3× o tamanho | download não começa; mostra o espaço necessário |
| Usuário cancela | download interrompido; nada é alterado |
| Conexão cai / arquivo truncado | tamanho não confere → descartado; nada é alterado |
| SHA-256 diferente (corrompido/adulterado) | descartado; nada é alterado |
| Imagem com hash diferente | descartado; nada é alterado |
| Pacote não corresponde ao manifesto ou formato futuro | recusado com mensagem |
| Erro durante a importação | `ROLLBACK`: banco permanece na versão anterior; imagens temporárias apagadas |
| Artigo do pacote mais antigo que o instalado | ignorado (sem rebaixamento) |
| Favoritos, notas, listas, histórico, preferências | ficam em `user.db`, que a atualização nunca abre |

Verificação automática: ao recuperar conexão, no máximo a cada 6 horas, se "Verificar automaticamente" estiver
ligado e a economia de bateria desligada. O usuário sempre decide se e quando baixar.

Todos os cenários acima têm testes em `app/test/package_service_test.dart` e `app/test/library_db_test.dart`.

## Publicar uma atualização

1. Revisar e publicar artigos no painel.
2. Painel › Publicação › "Gerar e publicar nova versão" (ou `npm run build:release` no servidor).
3. Servir `server/dist/updates/` em HTTPS (o próprio `npm start` atrás de um proxy TLS, ou CDN estática).
4. Para atualizar também a biblioteca **embarcada** em uma nova versão do app: `npm run build:content`
   (copia o pacote essencial para `app/assets/`) e gerar novo build do app.
