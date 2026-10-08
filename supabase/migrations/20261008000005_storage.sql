-- Buckets públicos de imagens. Cada usuário só escreve na própria pasta:
-- {bucket}/{auth.uid()}/{arquivo}

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars', 'avatars', true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('post-covers', 'post-covers', true, 8388608, array['image/jpeg', 'image/png', 'image/webp']),
  ('stories', 'stories', true, 8388608, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

create policy "Envio na minha pasta" on storage.objects
  for insert to authenticated
  with check (
    bucket_id in ('avatars', 'post-covers', 'stories')
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Atualizo arquivos da minha pasta" on storage.objects
  for update to authenticated
  using (
    bucket_id in ('avatars', 'post-covers', 'stories')
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Apago arquivos da minha pasta" on storage.objects
  for delete to authenticated
  using (
    bucket_id in ('avatars', 'post-covers', 'stories')
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
