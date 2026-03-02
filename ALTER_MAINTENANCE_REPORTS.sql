-- ============================================
-- ADD SUPERVISOR APPROVAL FIELDS TO MAINTENANCE_REPORTS
-- ============================================

ALTER TABLE maintenance_reports 
ADD COLUMN supervisor_id INT,
ADD COLUMN supervisor_approval_status VARCHAR(50) DEFAULT 'pending',
ADD COLUMN supervisor_approval_date DATETIME,
ADD COLUMN supervisor_notes TEXT,
ADD COLUMN checklist_data LONGTEXT,
ADD FOREIGN KEY (supervisor_id) REFERENCES users(id) ON DELETE SET NULL,
ADD INDEX idx_supervisor_approval_status (supervisor_approval_status);

-- ============================================
-- UPDATE REPORT STATUS VALUES
-- ============================================
UPDATE maintenance_reports 
SET report_status = 'draft' 
WHERE report_status IS NULL;

-- ============================================
-- VERIFY
-- ============================================
SELECT 'Columns added successfully' as message;
DESCRIBE maintenance_reports;
