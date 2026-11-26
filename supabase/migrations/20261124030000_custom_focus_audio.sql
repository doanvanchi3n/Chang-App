-- Chạy sau 20261124020000_tasks_and_focus_flow.sql.
-- Chỉ lưu mã lựa chọn âm thanh. Không upload file hay đường dẫn riêng tư lên Supabase.
BEGIN;
ALTER TYPE public.ambient_sound_type ADD VALUE IF NOT EXISTS 'CUSTOM';
COMMIT;

BEGIN;
ALTER TABLE public.focus_sessions ADD COLUMN IF NOT EXISTS custom_sound_id uuid;

CREATE OR REPLACE FUNCTION public.start_focus_session(
  p_id uuid,p_task uuid,p_step uuid,p_seconds integer,p_sound text
) RETURNS jsonb LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $$
DECLARE
  v_user uuid:=auth.uid(); v_task public.tasks; v_step public.subtasks;
  v_session public.focus_sessions; v_project text; v_now timestamptz:=clock_timestamp(); v_hash text;
  v_sound public.ambient_sound_type; v_custom uuid;
BEGIN
  IF v_user IS NULL THEN RAISE EXCEPTION 'Authentication required' USING ERRCODE='42501'; END IF;
  v_hash:=md5(jsonb_build_array(p_task,p_step,p_seconds,p_sound)::text);
  PERFORM pg_advisory_xact_lock(hashtextextended(v_user::text,0));
  SELECT * INTO v_session FROM public.focus_sessions WHERE id=p_id AND user_id=v_user;
  IF FOUND THEN
    IF v_session.start_fingerprint IS DISTINCT FROM v_hash THEN RAISE EXCEPTION 'Start request changed' USING ERRCODE='22023'; END IF;
    RETURN to_jsonb(v_session)||jsonb_build_object('server_now',clock_timestamp());
  END IF;
  IF p_id IS NULL OR p_seconds IS NULL OR p_seconds NOT BETWEEN 60 AND 10800
    OR p_sound IS NULL THEN
    RAISE EXCEPTION 'Invalid session settings' USING ERRCODE='22023';
  END IF;
  IF p_sound IN ('SILENT','WHITE_NOISE') THEN
    v_sound:=p_sound::public.ambient_sound_type;
  ELSIF p_sound ~ '^LOCAL:[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$' THEN
    v_sound:='CUSTOM'; v_custom:=substring(p_sound FROM 7)::uuid;
  ELSE RAISE EXCEPTION 'Invalid sound' USING ERRCODE='22023'; END IF;
  IF EXISTS(SELECT 1 FROM public.focus_sessions WHERE user_id=v_user AND status IN ('IN_PROGRESS','PAUSED','AWAITING_REVIEW')) THEN
    RAISE EXCEPTION 'An open session already exists' USING ERRCODE='23505';
  END IF;
  SELECT * INTO v_task FROM public.tasks WHERE id=p_task AND user_id=v_user AND NOT is_archived AND status<>'COMPLETED' FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Task unavailable' USING ERRCODE='22023'; END IF;
  IF p_step IS NOT NULL THEN
    SELECT * INTO v_step FROM public.subtasks WHERE id=p_step AND task_id=p_task AND NOT is_completed;
    IF NOT FOUND THEN RAISE EXCEPTION 'Step unavailable' USING ERRCODE='22023'; END IF;
  END IF;
  SELECT name INTO v_project FROM public.projects WHERE id=v_task.project_id AND user_id=v_user;
  v_now:=clock_timestamp();
  INSERT INTO public.focus_sessions(id,user_id,task_id,subtask_id,target_duration_seconds,
    status,ambient_sound,custom_sound_id,started_at,ended_at,running_since,last_event_at,task_title,step_title,step_order,project_name,start_fingerprint)
    VALUES(p_id,v_user,p_task,p_step,p_seconds,'IN_PROGRESS',v_sound,v_custom,
      v_now,NULL,v_now,v_now,v_task.title,v_step.title,v_step.order_index,v_project,v_hash)
    RETURNING * INTO v_session;
  RETURN to_jsonb(v_session)||jsonb_build_object('server_now',clock_timestamp());
END; $$;

CREATE OR REPLACE FUNCTION public.control_focus_session(
  p_id uuid,p_command uuid,p_revision integer,p_action text,p_at timestamptz,
  p_sound text DEFAULT NULL,p_complete boolean DEFAULT NULL,p_note text DEFAULT NULL
) RETURNS jsonb LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $$
DECLARE
  s public.focus_sessions; v_at timestamptz; v_end timestamptz; v_elapsed bigint; v_payload jsonb;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentication required' USING ERRCODE='42501'; END IF;
  -- Same lock order as planning/creation and step updates: user, task, session.
  PERFORM pg_advisory_xact_lock(hashtextextended(auth.uid()::text,0));
  SELECT * INTO s FROM public.focus_sessions WHERE id=p_id AND user_id=auth.uid();
  IF NOT FOUND THEN RAISE EXCEPTION 'Session unavailable' USING ERRCODE='42501'; END IF;
  PERFORM id FROM public.tasks WHERE id=s.task_id AND user_id=auth.uid() FOR UPDATE;
  SELECT * INTO s FROM public.focus_sessions WHERE id=p_id AND user_id=auth.uid() FOR UPDATE;
  v_payload:=jsonb_build_array(p_revision,p_action,p_at,p_sound,p_complete,p_note);
  IF s.last_command_id=p_command THEN
    IF s.last_command_payload IS DISTINCT FROM v_payload THEN
      RAISE EXCEPTION 'Command request changed' USING ERRCODE='22023';
    END IF;
    RETURN to_jsonb(s)||jsonb_build_object('server_now',clock_timestamp());
  END IF;
  IF p_command IS NULL OR p_revision IS NULL OR s.revision<>p_revision THEN
    RAISE EXCEPTION 'Session changed; refresh before retrying' USING ERRCODE='40001';
  END IF;
  IF p_action IS NULL OR p_action NOT IN ('PAUSE','RESUME','FINISH','SOUND','SAVE') OR p_at IS NULL THEN
    RAISE EXCEPTION 'Invalid session action' USING ERRCODE='22023';
  END IF;
  v_at:=least(clock_timestamp(),greatest(s.started_at,s.last_event_at,p_at));
  v_elapsed:=s.elapsed_milliseconds;
  IF s.status='IN_PROGRESS' THEN
    v_at:=greatest(s.running_since,v_at);
    v_elapsed:=least(s.target_duration_seconds::bigint*1000,
      s.elapsed_milliseconds+greatest(0,floor(extract(epoch FROM (v_at-s.running_since))*1000)::bigint));
    v_end:=s.running_since + ((s.target_duration_seconds::bigint*1000-s.elapsed_milliseconds)::double precision/1000)*interval '1 second';
  END IF;
  IF p_action='PAUSE' AND s.status='IN_PROGRESS' THEN
    s.elapsed_milliseconds:=v_elapsed; s.running_since:=NULL;
    IF v_elapsed>=s.target_duration_seconds::bigint*1000 THEN
      s.status:='AWAITING_REVIEW'; s.ended_at:=v_end;
    ELSE s.status:='PAUSED'; END IF;
  ELSIF p_action='RESUME' AND s.status='PAUSED' THEN
    s.status:='IN_PROGRESS'; s.running_since:=v_at;
  ELSIF p_action='FINISH' AND s.status IN ('IN_PROGRESS','PAUSED') THEN
    s.elapsed_milliseconds:=v_elapsed;
    s.ended_at:=CASE WHEN s.status='IN_PROGRESS' AND v_elapsed>=s.target_duration_seconds::bigint*1000 THEN v_end ELSE v_at END;
    s.running_since:=NULL; s.status:='AWAITING_REVIEW';
  ELSIF p_action='SOUND' AND s.status IN ('IN_PROGRESS','PAUSED') THEN
    IF p_sound IN ('SILENT','WHITE_NOISE') THEN
      s.ambient_sound:=p_sound::public.ambient_sound_type; s.custom_sound_id:=NULL;
    ELSIF p_sound ~ '^LOCAL:[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$' THEN
      s.ambient_sound:='CUSTOM'; s.custom_sound_id:=substring(p_sound FROM 7)::uuid;
    ELSE RAISE EXCEPTION 'Invalid sound' USING ERRCODE='22023'; END IF;
  ELSIF p_action='SAVE' AND s.status='AWAITING_REVIEW' THEN
    IF length(coalesce(p_note,''))>2000 THEN RAISE EXCEPTION 'Note too long' USING ERRCODE='22023'; END IF;
    IF p_complete IS TRUE AND s.subtask_id IS NOT NULL THEN
      PERFORM public.set_task_step_complete(s.task_id,s.subtask_id,true);
    END IF;
    s.note:=nullif(btrim(p_note),''); s.confirmed_step_complete:=p_complete;
    s.status:=CASE WHEN s.elapsed_milliseconds>=s.target_duration_seconds::bigint*1000
      THEN 'COMPLETED'::public.session_status ELSE 'EARLY_STOPPED'::public.session_status END;
  ELSE RAISE EXCEPTION 'Action is not valid in this phase' USING ERRCODE='40001';
  END IF;
  UPDATE public.focus_sessions SET status=s.status,running_since=s.running_since,
    elapsed_milliseconds=s.elapsed_milliseconds,
    actual_duration_seconds=(s.elapsed_milliseconds/1000)::integer,
    ended_at=s.ended_at,ambient_sound=s.ambient_sound,custom_sound_id=s.custom_sound_id,note=s.note,
    confirmed_step_complete=s.confirmed_step_complete,revision=s.revision+1,last_command_id=p_command,
    last_command_payload=v_payload,last_event_at=v_at
    WHERE id=s.id RETURNING * INTO s;
  RETURN to_jsonb(s)||jsonb_build_object('server_now',clock_timestamp());
END; $$;

REVOKE ALL ON FUNCTION public.start_focus_session(uuid,uuid,uuid,integer,text),
  public.control_focus_session(uuid,uuid,integer,text,timestamptz,text,boolean,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.start_focus_session(uuid,uuid,uuid,integer,text),
  public.control_focus_session(uuid,uuid,integer,text,timestamptz,text,boolean,text) TO authenticated;
NOTIFY pgrst,'reload schema';
COMMIT;
