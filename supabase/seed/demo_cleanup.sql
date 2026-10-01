-- Circle — remove TUDO do seed de demonstração (agências DEMO-*, cliente [DEMO]*, usuário de screenshots).
-- Não remove platform_admins nem usuários reais. Seguro para rodar mais de uma vez.
do $$
declare ags uuid[]; cls uuid[]; srcs uuid[];
begin
  select coalesce(array_agg(id),'{}') into ags from agencies where sigla like 'DEMO-%';
  select coalesce(array_agg(id),'{}') into cls from clients where nome like '[DEMO]%';
  select coalesce(array_agg(id),'{}') into srcs from sources where agency_id = any(ags);

  delete from notifications where client_id = any(cls);
  delete from process_events where client_id = any(cls) or process_id in (select id from processes where agency_id = any(ags));
  delete from client_processes where client_id = any(cls);
  delete from client_interests where client_id = any(cls);
  delete from process_requests where client_id = any(cls);
  delete from client_contacts where client_id = any(cls);
  delete from client_members where client_id = any(cls);
  delete from clients where id = any(cls);

  delete from director_votes where agenda_item_id in (select ai.id from agenda_items ai join meetings m on m.id = ai.meeting_id where m.agency_id = any(ags));
  delete from decisions where agency_id = any(ags);
  delete from agenda_items where meeting_id in (select id from meetings where agency_id = any(ags));
  delete from meetings where agency_id = any(ags);
  delete from processes where agency_id = any(ags);
  delete from process_types where agency_id = any(ags);
  delete from people where agency_id = any(ags);
  delete from org_units where agency_id = any(ags);
  delete from data_quality_issues where source_id = any(srcs);
  delete from raw_documents where source_id = any(srcs);
  delete from ingestion_runs where source_id = any(srcs);
  delete from sources where id = any(srcs);
  delete from agencies where id = any(ags);

  delete from auth.users where email = 'demo-screenshots@circle.invalid';
end $$;
