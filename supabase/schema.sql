-- Aceiro — schema do backend real (Supabase/Postgres)
-- Rode este arquivo inteiro no SQL Editor do seu projeto Supabase
-- (Project > SQL Editor > New query > colar > Run).

create table if not exists occurrences (
  id text primary key,
  status text not null check (status in ('rascunho', 'em_andamento', 'concluida')),
  created_at timestamptz not null default now(),
  focus jsonb not null,
  classification jsonb,
  confirmation jsonb,
  risk_calculation jsonb,
  recommendation jsonb,
  feedback jsonb
);

create index if not exists occurrences_created_at_idx on occurrences (created_at desc);

create table if not exists app_config (
  id text primary key default 'default',
  vegetation_types jsonb not null,
  risk_areas jsonb not null,
  resource_packages jsonb not null,
  risk_matrix jsonb not null,
  updated_at timestamptz not null default now()
);

alter table occurrences enable row level security;
alter table app_config enable row level security;

-- IMPORTANTE: o app roda hoje sem login por operador (workspace único
-- compartilhado, decisão do produto). Isso significa que a chave "anon"
-- pública do Supabase, por si só, dá acesso total de leitura/escrita a
-- estas tabelas para qualquer pessoa que tenha a URL do projeto — não há
-- isolamento por usuário. Aceitável para começar a operar com uma equipe
-- de confiança, mas ao crescer o uso real, o próximo passo de segurança é
-- adicionar autenticação (Supabase Auth) e trocar estas policies por
-- policies que checam auth.uid() / papéis de operador.
create policy "anon full access to occurrences" on occurrences
  for all using (true) with check (true);

create policy "anon full access to app_config" on app_config
  for all using (true) with check (true);
