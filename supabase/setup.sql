-- Blog da Gessica: rodar UMA vez no Supabase (SQL Editor > New query > Run)

-- 1) Tabela de posts
create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null default '',
  slug text unique,
  summary text not null default '',
  cover_url text,
  categories text[] not null default '{}',
  content_html text not null default '',
  reading_minutes int not null default 1,
  status text not null default 'draft' check (status in ('draft', 'published')),
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists posts_publicados_idx on public.posts (status, published_at desc);

-- updated_at automático
create or replace function public.tocar_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists posts_updated_at on public.posts;
create trigger posts_updated_at before update on public.posts
for each row execute function public.tocar_updated_at();

-- 2) Segurança (RLS): o público só lê o que já foi publicado e cuja data chegou;
--    a autora vê e edita apenas os próprios posts.
alter table public.posts enable row level security;

drop policy if exists "publico le publicados" on public.posts;
create policy "publico le publicados" on public.posts
  for select to anon, authenticated
  using (status = 'published' and published_at <= now());

drop policy if exists "autora le os seus" on public.posts;
create policy "autora le os seus" on public.posts
  for select to authenticated using (author_id = auth.uid());

drop policy if exists "autora cria" on public.posts;
create policy "autora cria" on public.posts
  for insert to authenticated with check (author_id = auth.uid());

drop policy if exists "autora edita" on public.posts;
create policy "autora edita" on public.posts
  for update to authenticated
  using (author_id = auth.uid()) with check (author_id = auth.uid());

drop policy if exists "autora apaga" on public.posts;
create policy "autora apaga" on public.posts
  for delete to authenticated using (author_id = auth.uid());

-- 3) Fotos: bucket público "imagens" (qualquer um vê, só a autora envia/apaga)
insert into storage.buckets (id, name, public)
values ('imagens', 'imagens', true)
on conflict (id) do nothing;

drop policy if exists "imagens autora envia" on storage.objects;
create policy "imagens autora envia" on storage.objects
  for insert to authenticated with check (bucket_id = 'imagens');

drop policy if exists "imagens autora apaga" on storage.objects;
create policy "imagens autora apaga" on storage.objects
  for delete to authenticated using (bucket_id = 'imagens' and owner = auth.uid());
