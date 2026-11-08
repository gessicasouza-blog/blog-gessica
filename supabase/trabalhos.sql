-- Portfólio de maquiagem: rodar UMA vez no Supabase (SQL Editor > New query > Run)

create table if not exists public.trabalhos (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  titulo text not null default '',
  tipo text not null default 'Social',
  data date not null default current_date,
  descricao text not null default '',
  fotos text[] not null default '{}',
  status text not null default 'draft' check (status in ('draft', 'published')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists trabalhos_publicados_idx on public.trabalhos (status, data desc);

drop trigger if exists trabalhos_updated_at on public.trabalhos;
create trigger trabalhos_updated_at before update on public.trabalhos
for each row execute function public.tocar_updated_at();

alter table public.trabalhos enable row level security;

drop policy if exists "publico le trabalhos" on public.trabalhos;
create policy "publico le trabalhos" on public.trabalhos
  for select to anon, authenticated using (status = 'published');

drop policy if exists "autora le seus trabalhos" on public.trabalhos;
create policy "autora le seus trabalhos" on public.trabalhos
  for select to authenticated using (author_id = auth.uid());

drop policy if exists "autora cria trabalho" on public.trabalhos;
create policy "autora cria trabalho" on public.trabalhos
  for insert to authenticated with check (author_id = auth.uid());

drop policy if exists "autora edita trabalho" on public.trabalhos;
create policy "autora edita trabalho" on public.trabalhos
  for update to authenticated using (author_id = auth.uid()) with check (author_id = auth.uid());

drop policy if exists "autora apaga trabalho" on public.trabalhos;
create policy "autora apaga trabalho" on public.trabalhos
  for delete to authenticated using (author_id = auth.uid());
