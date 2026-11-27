-- FEAT-10 / 11. Chạy sau 20261124040000_task_edit_steps.sql.
-- Không tạo dữ liệu mẫu, không thay đổi RLS hiện có.
BEGIN;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS completed_at timestamptz;
ALTER TABLE public.projects
  ADD COLUMN IF NOT EXISTS icon_name text NOT NULL DEFAULT 'folder',
  ADD COLUMN IF NOT EXISTS create_fingerprint text;

-- Với việc cũ, updated_at chỉ là mốc gần đúng vì trước đây chưa lưu ngày hoàn thành.
UPDATE public.tasks SET completed_at=updated_at
  WHERE status='COMPLETED' AND completed_at IS NULL;

CREATE OR REPLACE FUNCTION public.track_task_completion()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $$
BEGIN
  IF NEW.status='COMPLETED' THEN
    IF TG_OP='INSERT' THEN
      NEW.completed_at:=clock_timestamp();
    ELSIF OLD.status IS DISTINCT FROM NEW.status THEN
      NEW.completed_at:=clock_timestamp();
    ELSE
      NEW.completed_at:=OLD.completed_at;
    END IF;
  ELSE
    NEW.completed_at:=NULL;
  END IF;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS tr_tasks_completion ON public.tasks;
CREATE TRIGGER tr_tasks_completion BEFORE INSERT OR UPDATE ON public.tasks
  FOR EACH ROW EXECUTE FUNCTION public.track_task_completion();

GRANT SELECT, INSERT ON public.projects TO authenticated;
CREATE INDEX IF NOT EXISTS projects_user_created_idx ON public.projects(user_id,created_at DESC,id);

CREATE OR REPLACE FUNCTION public.create_study_project(
  p_id uuid,p_name text,p_description text,p_deadline timestamptz,p_color text,p_icon text
) RETURNS uuid LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $$
DECLARE v_user uuid:=auth.uid(); v_hash text; v_existing text;
BEGIN
  IF v_user IS NULL THEN RAISE EXCEPTION 'Authentication required' USING ERRCODE='42501'; END IF;
  v_hash:=md5(jsonb_build_array(p_name,p_description,p_deadline,p_color,p_icon)::text);
  PERFORM pg_advisory_xact_lock(hashtextextended(v_user::text,0));
  SELECT create_fingerprint INTO v_existing FROM public.projects WHERE id=p_id AND user_id=v_user;
  IF FOUND THEN
    IF v_existing IS DISTINCT FROM v_hash THEN RAISE EXCEPTION 'Creation request changed' USING ERRCODE='22023'; END IF;
    RETURN p_id;
  END IF;
  IF p_id IS NULL OR p_name IS NULL OR length(btrim(p_name)) NOT BETWEEN 1 AND 150
    OR length(coalesce(p_description,''))>4000
    OR p_color IS NULL OR p_color NOT IN ('#006BFF','#FFC83D','#FF8066','#28B463','#345D83','#E78AC3')
    OR p_icon IS NULL OR p_icon NOT IN ('folder','school','book') THEN
    RAISE EXCEPTION 'Invalid project' USING ERRCODE='22023';
  END IF;
  IF p_deadline IS NOT NULL AND p_deadline<=clock_timestamp() THEN
    RAISE EXCEPTION 'Deadline must be in the future' USING ERRCODE='22023';
  END IF;
  INSERT INTO public.projects(id,user_id,name,description,deadline,color_hex,icon_name,create_fingerprint)
    VALUES(p_id,v_user,btrim(p_name),nullif(btrim(p_description),''),p_deadline,p_color,p_icon,v_hash);
  RETURN p_id;
END $$;
REVOKE ALL ON FUNCTION public.create_study_project(uuid,text,text,timestamptz,text,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.create_study_project(uuid,text,text,timestamptz,text,text) TO authenticated;
NOTIFY pgrst, 'reload schema';
COMMIT;
