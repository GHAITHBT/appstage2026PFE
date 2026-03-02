-- Zone Management Table
-- Add this to your database for zone CRUD operations

USE maintenance_system;

-- Create zones table
CREATE TABLE IF NOT EXISTS zones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    location VARCHAR(200),
    created_by_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by_id) REFERENCES users(id),
    INDEX idx_name (name),
    INDEX idx_created_at (created_at)
);

-- Insert default zones (optional)
INSERT INTO zones (name, description, location) VALUES
('Zone A', 'First production zone', 'Floor 1'),
('Zone B', 'Second production zone', 'Floor 1'),
('Zone C', 'Assembly area', 'Floor 2'),
('Zone D', 'Maintenance workshop', 'Floor 2'),
('Zone E', 'Logistics area', 'Floor 3');

-- Update users table to use zone reference (if needed for foreign key)
-- ALTER TABLE users ADD FOREIGN KEY (zone) REFERENCES zones(name) ON DELETE SET NULL;
