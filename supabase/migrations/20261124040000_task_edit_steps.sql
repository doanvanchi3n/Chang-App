-- FEAT-07 / 08 / 09. Chạy sau các migration tasks_and_focus_flow và feat06_task_detail.
-- Không tạo dữ liệu mẫu. Tất cả RPC chạy với quyền người dùng và RLS hiện có.
BEGIN;
ALTER TABLE public.tasks
  ADD COLUMN IF NOT EXISTS last_edit_request uuid,
  ADD COLUMN IF NOT EXISTS last_edit_payload jsonb,
  ADD COLUMN IF NOT EXISTS last_steps_request uuid,
  ADD COLUMN IF NOT EXISTS last_steps_payload jsonb;

-- Defer only the uniqueness check while swapping order 1..5. Step IDs survive reordering.
DO $$ BEGIN
  IF EXISTS(SELECT 1 FROM pg_constraint WHERE conrelid='public.subtasks'::regclass
    AND conname='unique_task_subtask_order' AND NOT condeferrable) THEN
    ALTER TABLE public.subtasks DROP CONSTRAINT unique_task_subtask_order;
    ALTER TABLE public.subtasks ADD CONSTRAINT unique_task_subtask_order
      UNIQUE(task_id,order_index) DEFERRABLE INITIALLY IMMEDIATE;
  END IF;
END $$;
GRANT UPDATE(title,description,project_id,due_date,priority,estimated_minutes,
  last_edit_request,last_edit_payload,last_steps_request,last_steps_payload)
  ON public.tasks TO authenticated;
GRANT DELETE ON public.tasks,public.subtasks TO authenticated;
GRANT UPDATE(title,order_index,estimated_minutes,is_completed,completed_at) ON public.subtasks TO authenticated;

-- Renaming/reordering a step must not reset a task's manually selected status.
-- Recompute progress only when completion or membership actually changes.
CREATE OR REPLACE FUNCTION public.recalculate_task_progress()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $$
DECLARE v_task uuid; v_total integer; v_done integer; v_percent integer;
BEGIN
  IF TG_OP='UPDATE' THEN
    IF NEW.task_id=OLD.task_id AND NEW.is_completed IS NOT DISTINCT FROM OLD.is_completed THEN
      RETURN NULL;
    END IF;
  END IF;
  v_task:=CASE WHEN TG_OP='DELETE' THEN OLD.task_id ELSE NEW.task_id END;
  SELECT count(*),count(*) FILTER(WHERE is_completed) INTO v_total,v_done
    FROM public.subtasks WHERE task_id=v_task;
  v_percent:=CASE WHEN v_total=0 THEN 0 ELSE round(v_done::numeric/v_total*100)::integer END;
  UPDATE public.tasks SET progress_percentage=v_percent,
    status=CASE WHEN v_percent=100 THEN 'COMPLETED'::public.task_status
      WHEN v_percent>0 THEN 'IN_PROGRESS'::public.task_status ELSE 'TODO'::public.task_status END,
    updated_at=now() WHERE id=v_task;
  RETURN NULL;
END $$;

CREATE OR REPLACE FUNCTION public.save_task_details(
  p_task uuid,p_request uuid,p_expected timestamptz,p_fields jsonb
) RETURNS uuid LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $$
DECLARE t public.tasks; v_project uuid; v_due timestamptz; v_minutes integer;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentication required' USING ERRCODE='42501'; END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended(auth.uid()::text,0));
  SELECT * INTO t FROM public.tasks WHERE id=p_task AND user_id=auth.uid() AND NOT is_archived FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Task unavailable' USING ERRCODE='42501'; END IF;
  IF p_request IS NOT NULL AND t.last_edit_request=p_request THEN
    IF t.last_edit_payload IS DISTINCT FROM p_fields THEN RAISE EXCEPTION 'Request changed' USING ERRCODE='22023'; END IF;
    RETURN t.id;
  END IF;
  IF p_expected IS NULL OR t.updated_at<>p_expected THEN RAISE EXCEPTION 'Task changed' USING ERRCODE='40001'; END IF;
  IF p_request IS NULL OR p_fields IS NULL OR jsonb_typeof(p_fields)<>'object'
    OR coalesce(length(btrim(p_fields->>'title')),0) NOT BETWEEN 1 AND 200
    OR length(coalesce(p_fields->>'description',''))>4000
    OR coalesce(p_fields->>'priority','') NOT IN ('LOW','MEDIUM','HIGH') THEN
    RAISE EXCEPTION 'Invalid fields' USING ERRCODE='22023';
  END IF;
  v_project:=nullif(p_fields->>'project_id','')::uuid;
  v_due:=nullif(p_fields->>'due_date','')::timestamptz;
  v_minutes:=(p_fields->>'estimated_minutes')::integer;
  IF v_minutes IS NULL OR v_minutes NOT BETWEEN 1 AND 1440 THEN RAISE EXCEPTION 'Invalid estimate' USING ERRCODE='22023'; END IF;
  IF v_due IS DISTINCT FROM t.due_date AND v_due<=clock_timestamp() THEN RAISE EXCEPTION 'Deadline must be in the future' USING ERRCODE='22023'; END IF;
  IF v_project IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.projects WHERE id=v_project
    AND user_id=auth.uid() AND (status='ACTIVE' OR id=t.project_id)) THEN
    RAISE EXCEPTION 'Project unavailable' USING ERRCODE='22023';
  END IF;
  UPDATE public.tasks SET title=btrim(p_fields->>'title'),description=nullif(btrim(p_fields->>'description'),''),
    project_id=v_project,due_date=v_due,priority=(p_fields->>'priority')::public.task_priority,
    estimated_minutes=v_minutes,last_edit_request=p_request,last_edit_payload=p_fields WHERE id=t.id;
  RETURN t.id;
END $$;

CREATE OR REPLACE FUNCTION public.save_task_steps(
  p_task uuid,p_request uuid,p_expected timestamptz,p_steps jsonb
) RETURNS uuid LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $$
DECLARE t public.tasks; r record; v_id uuid; v_completed boolean;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentication required' USING ERRCODE='42501'; END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended(auth.uid()::text,0));
  SELECT * INTO t FROM public.tasks WHERE id=p_task AND user_id=auth.uid() AND NOT is_archived FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Task unavailable' USING ERRCODE='42501'; END IF;
  IF p_request IS NOT NULL AND t.last_steps_request=p_request THEN
    IF t.last_steps_payload IS DISTINCT FROM p_steps THEN RAISE EXCEPTION 'Request changed' USING ERRCODE='22023'; END IF;
    RETURN t.id;
  END IF;
  IF p_expected IS NULL OR t.updated_at<>p_expected THEN RAISE EXCEPTION 'Task changed' USING ERRCODE='40001'; END IF;
  IF p_request IS NULL OR p_steps IS NULL OR jsonb_typeof(p_steps)<>'array' THEN RAISE EXCEPTION 'Invalid steps' USING ERRCODE='22023'; END IF;
  IF jsonb_array_length(p_steps)>5 OR EXISTS(
    SELECT 1 FROM jsonb_array_elements(p_steps) x WHERE jsonb_typeof(x)<>'object'
      OR x->>'id' IS NULL OR coalesce(length(btrim(x->>'title')),0) NOT BETWEEN 1 AND 200
      OR coalesce((x->>'estimated_minutes')::integer,0) NOT BETWEEN 1 AND 1440
      OR jsonb_typeof(x->'is_completed') IS DISTINCT FROM 'boolean'
  ) OR (SELECT count(DISTINCT x->>'id') FROM jsonb_array_elements(p_steps) x)<>jsonb_array_length(p_steps) THEN
    RAISE EXCEPTION 'Provide up to 5 valid steps' USING ERRCODE='22023';
  END IF;
  IF EXISTS(SELECT 1 FROM public.focus_sessions s WHERE s.user_id=auth.uid() AND s.task_id=t.id
    AND s.status IN ('IN_PROGRESS','PAUSED','AWAITING_REVIEW') AND s.subtask_id IS NOT NULL
    AND NOT EXISTS(SELECT 1 FROM jsonb_array_elements(p_steps) x WHERE (x->>'id')::uuid=s.subtask_id)) THEN
    RAISE EXCEPTION 'Finish the open focus session before deleting its step' USING ERRCODE='22023';
  END IF;
  SET CONSTRAINTS public.unique_task_subtask_order DEFERRED;
  DELETE FROM public.subtasks s WHERE s.task_id=t.id
    AND NOT EXISTS(SELECT 1 FROM jsonb_array_elements(p_steps) x WHERE (x->>'id')::uuid=s.id);
  FOR r IN SELECT value,ordinality FROM jsonb_array_elements(p_steps) WITH ORDINALITY LOOP
    v_id:=(r.value->>'id')::uuid;
    v_completed:=(r.value->>'is_completed')::boolean;
    UPDATE public.subtasks SET title=btrim(r.value->>'title'),order_index=r.ordinality::integer,
      estimated_minutes=(r.value->>'estimated_minutes')::integer,is_completed=v_completed,
      completed_at=CASE WHEN v_completed THEN CASE WHEN is_completed THEN completed_at ELSE clock_timestamp() END ELSE NULL END
      WHERE id=v_id AND task_id=t.id;
    IF NOT FOUND THEN
      INSERT INTO public.subtasks(id,task_id,title,order_index,estimated_minutes,is_completed,completed_at)
        VALUES(v_id,t.id,btrim(r.value->>'title'),r.ordinality::integer,(r.value->>'estimated_minutes')::integer,
          v_completed,CASE WHEN v_completed THEN clock_timestamp() ELSE NULL END);
    END IF;
  END LOOP;
  SET CONSTRAINTS public.unique_task_subtask_order IMMEDIATE;
  UPDATE public.tasks SET last_steps_request=p_request,last_steps_payload=p_steps WHERE id=t.id;
  RETURN t.id;
END $$;

CREATE OR REPLACE FUNCTION public.delete_task_checked(p_task uuid,p_expected timestamptz)
RETURNS void LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $$
DECLARE t public.tasks;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentication required' USING ERRCODE='42501'; END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended(auth.uid()::text,0));
  SELECT * INTO t FROM public.tasks WHERE id=p_task AND user_id=auth.uid() FOR UPDATE;
  IF NOT FOUND THEN RETURN; END IF;
  IF p_expected IS NULL OR t.updated_at<>p_expected THEN RAISE EXCEPTION 'Task changed' USING ERRCODE='40001'; END IF;
  IF EXISTS(SELECT 1 FROM public.focus_sessions WHERE user_id=auth.uid() AND task_id=t.id
    AND status IN ('IN_PROGRESS','PAUSED','AWAITING_REVIEW')) THEN
    RAISE EXCEPTION 'Finish the open focus session first' USING ERRCODE='22023';
  END IF;
  DELETE FROM public.tasks WHERE id=t.id;
END $$;
REVOKE ALL ON FUNCTION public.save_task_details(uuid,uuid,timestamptz,jsonb),
  public.save_task_steps(uuid,uuid,timestamptz,jsonb),public.delete_task_checked(uuid,timestamptz) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.save_task_details(uuid,uuid,timestamptz,jsonb),
  public.save_task_steps(uuid,uuid,timestamptz,jsonb),public.delete_task_checked(uuid,timestamptz) TO authenticated;
NOTIFY pgrst,'reload schema';
COMMIT;
