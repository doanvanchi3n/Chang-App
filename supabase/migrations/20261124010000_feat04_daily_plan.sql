-- FEAT-04 / M02. Chạy toàn bộ file trong Supabase SQL Editor trước khi mở M02.
-- Không tạo dữ liệu mẫu. Giữ quyền sở hữu qua RLS và auth.uid().
BEGIN;

ALTER TABLE public.tasks
  ADD COLUMN IF NOT EXISTS estimated_minutes integer
    CHECK (estimated_minutes BETWEEN 1 AND 1440),
  ADD COLUMN IF NOT EXISTS daily_order integer CHECK (daily_order >= 0);

CREATE TABLE IF NOT EXISTS public.daily_plans (
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_date date NOT NULL,
  available_minutes integer NOT NULL CHECK (available_minutes BETWEEN 1 AND 1440),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, plan_date)
);
ALTER TABLE public.daily_plans ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS daily_plans_owner ON public.daily_plans;
CREATE POLICY daily_plans_owner ON public.daily_plans TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
DROP TRIGGER IF EXISTS tr_daily_plans_updated_at ON public.daily_plans;
CREATE TRIGGER tr_daily_plans_updated_at BEFORE UPDATE ON public.daily_plans
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

GRANT SELECT, INSERT, UPDATE ON public.daily_plans TO authenticated;
GRANT SELECT ON public.tasks, public.subtasks, public.user_preferences TO authenticated;
GRANT UPDATE (scheduled_date, estimated_minutes, daily_order)
  ON public.tasks TO authenticated;

CREATE OR REPLACE FUNCTION public.save_daily_plan(
  p_date date,
  p_available_minutes integer,
  p_plan_updated_at timestamptz,
  p_today_snapshot jsonb,
  p_tasks jsonb
) RETURNS integer
LANGUAGE plpgsql SECURITY INVOKER SET search_path = '' AS $$
DECLARE
  v_user uuid := auth.uid();
  v_updated_at timestamptz;
  v_count integer;
BEGIN
  IF v_user IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
  END IF;
  IF p_date IS NULL OR p_available_minutes IS NULL
      OR p_available_minutes NOT BETWEEN 1 AND 1440
      OR p_tasks IS NULL OR jsonb_typeof(p_tasks) <> 'array'
      OR p_today_snapshot IS NULL OR jsonb_typeof(p_today_snapshot) <> 'array' THEN
    RAISE EXCEPTION 'Invalid daily plan' USING ERRCODE = '22023';
  END IF;
  IF EXISTS (
    SELECT 1 FROM jsonb_to_recordset(p_tasks)
      AS x(id uuid, estimated_minutes integer, updated_at timestamptz)
    WHERE x.id IS NULL OR x.updated_at IS NULL OR x.estimated_minutes IS NULL
      OR x.estimated_minutes NOT BETWEEN 1 AND 1440
  ) OR (SELECT count(DISTINCT x.id) FROM jsonb_to_recordset(p_tasks) AS x(id uuid))
      <> jsonb_array_length(p_tasks) THEN
    RAISE EXCEPTION 'Invalid task selection or duration' USING ERRCODE = '22023';
  END IF;

  -- Serialize saves for one user; the entire function commits or rolls back.
  PERFORM pg_advisory_xact_lock(hashtextextended(v_user::text, 0));
  SELECT updated_at INTO v_updated_at FROM public.daily_plans
    WHERE user_id = v_user AND plan_date = p_date FOR UPDATE;
  IF v_updated_at IS DISTINCT FROM p_plan_updated_at THEN
    RAISE EXCEPTION 'Plan changed; reload before saving' USING ERRCODE = '40001';
  END IF;

  PERFORM t.id FROM public.tasks t
    WHERE t.user_id = v_user AND (
      t.scheduled_date = p_date OR
      t.id IN (SELECT x.id FROM jsonb_to_recordset(p_tasks) AS x(id uuid))
    ) ORDER BY t.id FOR UPDATE;

  -- Detect changes to the current queue, including removed/completed tasks.
  IF EXISTS (
    SELECT 1 FROM public.tasks t
    FULL JOIN jsonb_to_recordset(p_today_snapshot)
      AS x(id uuid, updated_at timestamptz) ON x.id = t.id
    WHERE (
      t.user_id = v_user AND t.scheduled_date = p_date
      AND NOT t.is_archived AND t.status IN ('TODO', 'IN_PROGRESS')
      AND (x.id IS NULL OR x.updated_at IS DISTINCT FROM t.updated_at)
    ) OR (
      x.id IS NOT NULL AND (t.id IS NULL OR t.user_id <> v_user
        OR t.scheduled_date IS DISTINCT FROM p_date OR t.is_archived
        OR t.status NOT IN ('TODO', 'IN_PROGRESS')
        OR x.updated_at IS DISTINCT FROM t.updated_at)
    )
  ) THEN
    RAISE EXCEPTION 'Tasks changed; reload before saving' USING ERRCODE = '40001';
  END IF;

  IF EXISTS (
    SELECT 1 FROM jsonb_to_recordset(p_tasks)
      AS x(id uuid, updated_at timestamptz)
    LEFT JOIN public.tasks t ON t.id = x.id AND t.user_id = v_user
    WHERE t.id IS NULL OR t.is_archived OR t.status NOT IN ('TODO', 'IN_PROGRESS')
      OR t.scheduled_date > p_date OR t.updated_at IS DISTINCT FROM x.updated_at
  ) THEN
    RAISE EXCEPTION 'Selected tasks changed; reload before saving' USING ERRCODE = '40001';
  END IF;

  -- Removing a task from this day's draft returns it to Inbox, without deleting it.
  UPDATE public.tasks t SET scheduled_date = NULL, daily_order = NULL
    WHERE t.user_id = v_user AND t.scheduled_date = p_date
      AND NOT t.is_archived AND t.status IN ('TODO', 'IN_PROGRESS')
      AND t.id NOT IN (SELECT x.id FROM jsonb_to_recordset(p_tasks) AS x(id uuid));

  UPDATE public.tasks t
    SET scheduled_date = p_date,
        estimated_minutes = (x.value->>'estimated_minutes')::integer,
        daily_order = (x.ordinality - 1)::integer
    FROM jsonb_array_elements(p_tasks) WITH ORDINALITY AS x(value, ordinality)
    WHERE t.id = (x.value->>'id')::uuid AND t.user_id = v_user;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> jsonb_array_length(p_tasks) THEN
    RAISE EXCEPTION 'Not all tasks were saved' USING ERRCODE = '40001';
  END IF;

  INSERT INTO public.daily_plans(user_id, plan_date, available_minutes)
    VALUES (v_user, p_date, p_available_minutes)
    ON CONFLICT (user_id, plan_date) DO UPDATE
      SET available_minutes = excluded.available_minutes;
  RETURN v_count;
END;
$$;

REVOKE ALL ON FUNCTION public.save_daily_plan(date, integer, timestamptz, jsonb, jsonb)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.save_daily_plan(date, integer, timestamptz, jsonb, jsonb)
  TO authenticated;
NOTIFY pgrst, 'reload schema';
COMMIT;
