-- Lucky Web V6: customer workspace starts empty.
-- Run once after the original Lucky Web demo schema.
-- It removes only the known demo seed rows and prevents future auto-seeding.

DELETE FROM public.lw_demo_activity
WHERE title IN ('رزرو بازدید جدید','فایل جدید دریافت شد','گزارش مذاکره مالک','محتوای جدید آماده شد');

DELETE FROM public.lw_demo_properties
WHERE title IN ('آپارتمان مدرن — معالی‌آباد','ویلای نوساز — قصرالدشت','دفتر اداری — فرهنگ‌شهر','پنت‌هاوس — عفیف‌آباد');

CREATE OR REPLACE FUNCTION public.lw_bootstrap_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.lw_profiles(id, full_name)
  VALUES (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1))
  )
  ON CONFLICT (id) DO NOTHING;

  -- Intentionally no demo properties/activity are created here.
  RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created_lw ON auth.users;
CREATE TRIGGER on_auth_user_created_lw
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.lw_bootstrap_user();
