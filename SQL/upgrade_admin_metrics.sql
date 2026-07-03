-- Create the platform_statistics view to replace HEAD requests
CREATE OR REPLACE VIEW platform_statistics AS
SELECT 
  (SELECT COUNT(*) FROM profiles) as total_students,
  (SELECT COUNT(*) FROM clubs) as active_clubs,
  (SELECT COUNT(*) FROM events) as total_events,
  (SELECT COUNT(*) FROM profiles WHERE role IN ('admin', 'super_admin', 'executive', 'member')) as active_members,
  (SELECT COUNT(*) FROM profiles WHERE role = 'executive') as total_executives,
  (SELECT COUNT(*) FROM content_reports WHERE status = 'pending') as pending_reports,
  (SELECT COUNT(*) FROM content_reports WHERE status = 'pending' AND severity = 'high') as high_risk_reports,
  (SELECT COUNT(*) FROM content_reports WHERE status = 'resolved' AND resolved_at >= current_date) as resolved_today_reports;

-- Grant access to authenticated users
GRANT SELECT ON platform_statistics TO authenticated;
