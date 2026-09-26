# Lucky Web — Premium Real Estate SaaS Demo v2

نسخه ارتقایافته Demo برای ارائه حرفه‌ای پلتفرم Lucky Web.

## مبنای محصول
- امکانات چهار Package از PDF کاتالوگ اصلی استخراج شده‌اند.
- فایل نمونه مشتری فقط برای درک الگوی UX استفاده شده و داده مشتری وارد Demo نشده است.
- Branding با لوگوی Lucky Web انجام شده است.

## اجرا
```bash
npm install
npm run dev
```
سپس Vite آدرس محلی، معمولاً `http://localhost:5173/` را نمایش می‌دهد.

## اتصال واقعی به Supabase
این نسخه برای Authentication و داده‌های اختصاصی هر User از Supabase استفاده می‌کند.

1. `.env.example` را به `.env` کپی کن.
2. مقدارهای زیر را وارد کن:
```env
VITE_SUPABASE_URL=https://YOUR-PROJECT.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_OR_ANON_KEY
```
3. فایل `LUCKYWEB_DEMO_SCHEMA.sql` را یک‌بار در Supabase SQL Editor اجرا کن.
4. دوباره `npm run dev` را اجرا کن.

رمز عبور هیچ‌وقت در جدول‌های Demo ذخیره نمی‌شود و فقط Supabase Auth مسئول Credential و Session است.

## قابلیت‌های v2
- Dark / Light mode با ذخیره ترجیح کاربر
- Supabase Authentication: Sign Up / Login / Logout / Session
- داده‌های Demo مستقل برای هر User با RLS
- پروفایل و ترجیحات کاربر
- Layout switcher: Classic / Header / Compact / Minimal / Detailed / Futuristic
- Sidebar: Expanded / Collapsed / Hidden
- Landing تعاملی با Hero، تصویر واقعی، Scroll reveal و Count-up
- Dashboard تعاملی با وضعیت Locked / Upgrade
- Loading / Empty / Error / Toast states
- Responsive اختصاصی برای Mobile / Tablet / Desktop
- Reduced-motion support
- SVG icon system؛ بدون Emoji
- کاتالوگ PDF داخل پروژه
- Real-estate imagery برای Hero و Showcase

## Build
```bash
npm run build
```
خروجی در `dist/` ساخته می‌شود و برای هاست استاتیک قابل انتشار است.

## نکته امنیتی
هیچ Secret یا Service Role Key را در Frontend قرار نده. فقط Publishable/Anon key مجاز است. RLS را روی جداول فعال نگه دار.
