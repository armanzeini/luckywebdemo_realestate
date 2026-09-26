# Lucky Web V6 — clean product pass from V5

This version is based directly on **Lucky Web V5 — Dashboard Final**.

## Fixed
- Dashboard navigation no longer replaces the whole application DOM on every menu click.
- Theme, layout and sidebar changes are applied in-place and persisted per authenticated user.
- Selected package is persisted per authenticated user, so a browser refresh does not silently return to Bronze.
- Customer workspace is data-first: no hard-coded customer/property/activity demo records are shown.
- Added migration `supabase_migration_003_empty_customer_workspace.sql` to remove the known seed rows and stop future auto-seeding.
- Added distinct package accents: Bronze / Silver / Gold / Exclusive.
- Added unique navigation icons per module.
- Added an auto-style visual banner rail with four real-estate image slides.
- Added real Before / After image examples as presentation-only visuals.
- Added a "Final Version — How it works" explanation block to each feature page.
- Removed Google Fonts network dependency.
- Added a favicon so `/favicon.ico` is no longer requested as a missing asset.

## Data policy
Mock UI content is used only to explain how a feature will work. Customer records, property records, team records, activities and KPI values are not pre-populated.
