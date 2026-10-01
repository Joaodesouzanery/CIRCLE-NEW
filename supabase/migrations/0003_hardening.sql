-- Circle — Migração 0003: endurecimento apontado pelo advisor de segurança do Supabase
alter function public.touch_updated_at() set search_path = public;
alter function public.normalize_nup(text) set search_path = public;

-- helpers de RLS: usados só por policies de usuários autenticados
revoke execute on function public.is_client_member(uuid) from public, anon;
revoke execute on function public.is_platform_admin() from public, anon;
do $$ begin
  if exists (select 1 from pg_proc where proname = 'rls_auto_enable' and pronamespace = 'public'::regnamespace) then
    revoke execute on function public.rls_auto_enable() from public, anon, authenticated;
  end if;
end $$;
