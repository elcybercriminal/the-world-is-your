-- PRISME 0.1.0 · Run once in the SQL Editor of a NEW dedicated Supabase project.
-- Never run against an existing application's schema without a migration review.
begin;
create table public.profiles (
 id uuid primary key references auth.users on delete cascade,
 username text not null unique check (username ~ '^[a-z0-9_.]{3,24}$'),
 name text not null default '' check(length(name)<=60),
 bio text not null default '' check(length(bio)<=200),
 avatar text not null default '' check(avatar='' or avatar ~ '^https://'),
 website text not null default '' check(website='' or website ~ '^https://'),
 created_at timestamptz not null default now()
);
create function public.new_profile() returns trigger language plpgsql security definer set search_path=public as $$
begin insert into public.profiles(id,username) values(new.id,'user_'||substr(md5(new.id::text),1,18)); return new; end $$;
create trigger on_prisme_user after insert on auth.users for each row execute function public.new_profile();
create table public.blocks(user_id uuid references public.profiles on delete cascade,blocked_id uuid references public.profiles on delete cascade,primary key(user_id,blocked_id),check(user_id<>blocked_id));
create function public.is_blocked(a uuid,b uuid) returns boolean language sql stable security definer set search_path=public as $$select exists(select 1 from blocks where (user_id=a and blocked_id=b) or (user_id=b and blocked_id=a))$$;
create function public.valid_media(media jsonb) returns boolean language plpgsql immutable set search_path=public as $$
declare m jsonb;u text;
begin
 if jsonb_typeof(media)<>'array' or jsonb_array_length(media) not between 1 and 10 then return false;end if;
 for m in select * from jsonb_array_elements(media) loop
  u=m->>'url';
  if u is null or length(u)>4096 or u !~ '^https://' or coalesce(m->>'type','') not in ('image','video','embed') then return false;end if;
  if m->>'type'='embed' and u !~ '^https://(www\.youtube-nocookie\.com/embed/[A-Za-z0-9_-]{11}|player\.vimeo\.com/video/[0-9]+|www\.dailymotion\.com/embed/video/[A-Za-z0-9]+)$' then return false;end if;
 end loop;return true;
end $$;
create table public.posts(id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles on delete cascade,caption text not null default '' check(length(caption)<=2200),media jsonb not null check(public.valid_media(media)),created_at timestamptz not null default now());
create index posts_created on public.posts(created_at desc);
create index posts_author on public.posts(user_id,created_at desc);
create table public.likes(post_id uuid references public.posts on delete cascade,user_id uuid references public.profiles on delete cascade,primary key(post_id,user_id));
create table public.saves(post_id uuid references public.posts on delete cascade,user_id uuid references public.profiles on delete cascade,primary key(post_id,user_id));
create table public.comments(id uuid primary key default gen_random_uuid(),post_id uuid not null references public.posts on delete cascade,user_id uuid not null references public.profiles on delete cascade,body text not null check(length(trim(body)) between 1 and 1000),created_at timestamptz not null default now());
create index comments_post on public.comments(post_id,created_at);
create table public.follows(follower_id uuid references public.profiles on delete cascade,following_id uuid references public.profiles on delete cascade,primary key(follower_id,following_id),check(follower_id<>following_id));
create index follows_target on public.follows(following_id);
create table public.threads(id uuid primary key default gen_random_uuid(),user_a uuid not null references public.profiles on delete cascade,user_b uuid not null references public.profiles on delete cascade,created_at timestamptz not null default now(),unique(user_a,user_b),check(user_a<user_b));
create function public.is_thread_member(t uuid) returns boolean language sql stable security definer set search_path=public as $$select exists(select 1 from threads where id=t and auth.uid() in(user_a,user_b) and not public.is_blocked(user_a,user_b))$$;
create function public.can_read_chat_file(thread_path text) returns boolean language sql stable security definer set search_path=public as $$select exists(select 1 from threads where id::text=thread_path and auth.uid() in(user_a,user_b) and not public.is_blocked(user_a,user_b))$$;
create table public.messages(id uuid primary key default gen_random_uuid(),thread_id uuid not null references public.threads on delete cascade,sender_id uuid not null references public.profiles on delete cascade,kind text not null check(kind in ('text','image','video','audio')),body text not null default '' check(length(body)<=4000),media_path text not null default '',created_at timestamptz not null default now(),read_at timestamptz,
 check((kind='text' and length(trim(body))>0 and media_path='') or(kind<>'text' and media_path like thread_id::text||'/'||sender_id::text||'/%')));
create index messages_thread on public.messages(thread_id,created_at desc);
create table public.reports(id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles on delete cascade,post_id uuid references public.posts on delete set null,reason text not null check(length(trim(reason)) between 1 and 2000),created_at timestamptz not null default now());
-- RLS is enforced for every table. No anonymous access, no client administrator flag.
alter table public.profiles enable row level security;
alter table public.blocks enable row level security;
alter table public.posts enable row level security;
alter table public.likes enable row level security;
alter table public.saves enable row level security;
alter table public.comments enable row level security;
alter table public.follows enable row level security;
alter table public.threads enable row level security;
alter table public.messages enable row level security;
alter table public.reports enable row level security;
create policy profiles_read on public.profiles for select to authenticated using(not public.is_blocked(auth.uid(),id));
create policy profiles_edit on public.profiles for update to authenticated using(id=auth.uid()) with check(id=auth.uid());
create policy blocks_own on public.blocks for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy posts_read on public.posts for select to authenticated using(not public.is_blocked(auth.uid(),user_id));
create policy posts_write on public.posts for insert to authenticated with check(user_id=auth.uid());
create policy posts_delete on public.posts for delete to authenticated using(user_id=auth.uid());
create policy likes_read on public.likes for select to authenticated using(exists(select 1 from public.posts where id=post_id));
create policy likes_add on public.likes for insert to authenticated with check(user_id=auth.uid() and exists(select 1 from public.posts where id=post_id));
create policy likes_remove on public.likes for delete to authenticated using(user_id=auth.uid());
create policy saves_own on public.saves for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid() and exists(select 1 from public.posts where id=post_id));
create policy comments_read on public.comments for select to authenticated using(not public.is_blocked(auth.uid(),user_id) and exists(select 1 from public.posts where id=post_id));
create policy comments_add on public.comments for insert to authenticated with check(user_id=auth.uid() and exists(select 1 from public.posts where id=post_id));
create policy comments_delete on public.comments for delete to authenticated using(user_id=auth.uid());
create policy follows_read on public.follows for select to authenticated using(not public.is_blocked(auth.uid(),follower_id) and not public.is_blocked(auth.uid(),following_id));
create policy follows_add on public.follows for insert to authenticated with check(follower_id=auth.uid() and not public.is_blocked(follower_id,following_id));
create policy follows_remove on public.follows for delete to authenticated using(follower_id=auth.uid());
create policy threads_read on public.threads for select to authenticated using(public.is_thread_member(id));
create policy messages_read on public.messages for select to authenticated using(public.is_thread_member(thread_id));
create policy messages_send on public.messages for insert to authenticated with check(sender_id=auth.uid() and public.is_thread_member(thread_id) and read_at is null);
create policy messages_receipt on public.messages for update to authenticated using(sender_id<>auth.uid() and public.is_thread_member(thread_id)) with check(sender_id<>auth.uid() and public.is_thread_member(thread_id));
create policy reports_send on public.reports for insert to authenticated with check(user_id=auth.uid() and exists(select 1 from public.posts where id=post_id));
-- Explicit column privileges protect immutable metadata and message contents.
revoke all on public.profiles,public.blocks,public.posts,public.likes,public.saves,public.comments,public.follows,public.threads,public.messages,public.reports from anon,authenticated;
grant select on public.profiles,public.posts,public.likes,public.saves,public.comments,public.follows,public.threads,public.messages,public.blocks to authenticated;
grant update(username,name,bio,avatar,website) on public.profiles to authenticated;
grant insert(user_id,caption,media) on public.posts to authenticated;
grant delete on public.posts to authenticated;
grant insert,delete on public.likes,public.saves,public.follows,public.blocks to authenticated;
grant insert(post_id,user_id,body),delete on public.comments to authenticated;
grant insert(thread_id,sender_id,kind,body,media_path),update(read_at) on public.messages to authenticated;
grant insert(user_id,post_id,reason) on public.reports to authenticated;
create function public.open_thread(peer_id uuid) returns jsonb language plpgsql security definer set search_path=public as $$
declare t public.threads;a uuid;b uuid;
begin
 if auth.uid() is null or peer_id=auth.uid() or public.is_blocked(auth.uid(),peer_id) then raise exception 'Conversation non autorisée';end if;
 if not exists(select 1 from profiles where id=peer_id) then raise exception 'Compte introuvable';end if;
 a=least(auth.uid(),peer_id);b=greatest(auth.uid(),peer_id);
 insert into threads(user_a,user_b) values(a,b) on conflict(user_a,user_b) do nothing;
 select * into t from threads where user_a=a and user_b=b;
 return to_jsonb(t);
end $$;
create function public.inbox() returns jsonb language sql stable security invoker set search_path=public as $$
 select coalesce(jsonb_agg(row_data order by sort_date desc),'[]'::jsonb) from (
 select jsonb_build_object('id',t.id,'user_a',t.user_a,'user_b',t.user_b,'created_at',t.created_at,'peer',to_jsonb(p),'last',(select to_jsonb(m) from messages m where m.thread_id=t.id order by m.created_at desc limit 1),'unread',(select count(*) from messages m where m.thread_id=t.id and m.sender_id<>auth.uid() and m.read_at is null)) row_data,
 coalesce((select max(m.created_at) from messages m where m.thread_id=t.id),t.created_at) sort_date
 from threads t join profiles p on p.id=case when t.user_a=auth.uid() then t.user_b else t.user_a end
 where auth.uid() in(t.user_a,t.user_b)
 ) inbox_rows
$$;
revoke execute on function public.new_profile(),public.open_thread(uuid),public.inbox(),public.is_blocked(uuid,uuid),public.is_thread_member(uuid),public.can_read_chat_file(text) from public,anon;
grant execute on function public.open_thread(uuid),public.inbox(),public.is_blocked(uuid,uuid),public.is_thread_member(uuid),public.can_read_chat_file(text) to authenticated;
-- Public publication media; private conversation media with one-hour signed links.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values
('media','media',true,52428800,array['image/jpeg','image/png','image/webp','image/gif','video/mp4','video/webm','video/quicktime']),
('chat-media','chat-media',false,52428800,array['image/jpeg','image/png','image/webp','image/gif','video/mp4','video/webm','video/quicktime','audio/webm','audio/ogg','audio/mp4','audio/mpeg','audio/wav']);
create policy media_upload on storage.objects for insert to authenticated with check(bucket_id='media' and (storage.foldername(name))[1]=auth.uid()::text);
create policy media_select on storage.objects for select to authenticated using(bucket_id='media');
create policy media_delete on storage.objects for delete to authenticated using(bucket_id='media' and (storage.foldername(name))[1]=auth.uid()::text);
create policy chat_upload on storage.objects for insert to authenticated with check(bucket_id='chat-media' and (storage.foldername(name))[2]=auth.uid()::text and public.can_read_chat_file((storage.foldername(name))[1]));
create policy chat_read on storage.objects for select to authenticated using(bucket_id='chat-media' and public.can_read_chat_file((storage.foldername(name))[1]));
create policy chat_delete on storage.objects for delete to authenticated using(bucket_id='chat-media' and (storage.foldername(name))[2]=auth.uid()::text);
commit;
