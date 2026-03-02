"""
Database Migration Script
Adds new columns and tables to support new features
"""

import os
from app import create_app, db
from app.models import User, Material, Machine, MaintenanceSchedule, MaintenanceReport
from app.models import SparePartsDemand, StockMovement, StockAlert, MaterialReturn
from sqlalchemy import text

# Create app
app = create_app(os.getenv('FLASK_ENV', 'development'))

def run_migration():
    """Run database migration to add new columns and tables"""
    with app.app_context():
        connection = db.engine.raw_connection()
        cursor = connection.cursor()
        
        try:
            print("Starting database migration...")
            
            # 1. Add zone column to users table if it doesn't exist
            print("✓ Adding zone column to users table...")
            try:
                cursor.execute("ALTER TABLE users ADD COLUMN zone VARCHAR(100) AFTER department")
                print("  → zone column added")
            except Exception as e:
                if "Duplicate column name" in str(e):
                    print("  → zone column already exists")
                else:
                    raise
            
            # 2. Add new columns to maintenance_reports table
            print("✓ Adding columns to maintenance_reports table...")
            
            new_report_columns = [
                ("report_type", "VARCHAR(50) DEFAULT 'standard'"),
                ("technician_zone", "VARCHAR(100)"),
                ("machine_condition", "VARCHAR(50)"),
                ("machine_condition_after", "VARCHAR(50)"),
                ("environmental_conditions", "TEXT"),
                ("safety_observations", "TEXT"),
                ("tools_used", "TEXT"),
            ]
            
            for col_name, col_def in new_report_columns:
                try:
                    cursor.execute(f"ALTER TABLE maintenance_reports ADD COLUMN {col_name} {col_def}")
                    print(f"  → {col_name} column added")
                except Exception as e:
                    if "Duplicate column name" in str(e):
                        print(f"  → {col_name} column already exists")
                    else:
                        raise
            
            # 3. Add new columns to spare_parts_demands table
            print("✓ Adding columns to spare_parts_demands table...")
            
            new_demand_columns = [
                ("quantity_returned", "INT DEFAULT 0"),
                ("return_date", "DATETIME"),
                ("return_notes", "TEXT"),
            ]
            
            for col_name, col_def in new_demand_columns:
                try:
                    cursor.execute(f"ALTER TABLE spare_parts_demands ADD COLUMN {col_name} {col_def}")
                    print(f"  → {col_name} column added")
                except Exception as e:
                    if "Duplicate column name" in str(e):
                        print(f"  → {col_name} column already exists")
                    else:
                        raise
            
            # 4. Add new columns to stock_movements table
            print("✓ Adding columns to stock_movements table...")
            
            new_movement_columns = [
                ("return_reason", "TEXT"),
            ]
            
            for col_name, col_def in new_movement_columns:
                try:
                    cursor.execute(f"ALTER TABLE stock_movements ADD COLUMN {col_name} {col_def}")
                    print(f"  → {col_name} column added")
                except Exception as e:
                    if "Duplicate column name" in str(e):
                        print(f"  → {col_name} column already exists")
                    else:
                        raise
            
            # 5. Update stock_movements movement_type enum to include 'returned'
            print("✓ Updating stock_movements movement_type enum...")
            try:
                cursor.execute("""
                    ALTER TABLE stock_movements 
                    MODIFY COLUMN movement_type ENUM('addition', 'withdrawal', 'adjustment', 'allocated', 'fulfilled', 'returned') NOT NULL
                """)
                print("  → movement_type enum updated")
            except Exception as e:
                if "Duplicate" in str(e):
                    print("  → movement_type enum already updated")
                else:
                    raise
            
            # 6. Create material_returns table
            print("✓ Creating material_returns table...")
            try:
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS material_returns (
                        id INT AUTO_INCREMENT PRIMARY KEY,
                        demand_id INT NOT NULL,
                        material_id INT NOT NULL,
                        quantity_returned INT NOT NULL,
                        return_reason TEXT,
                        condition_of_material VARCHAR(50),
                        returned_by_id INT,
                        received_by_id INT,
                        return_status VARCHAR(50) DEFAULT 'pending',
                        notes TEXT,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        processed_at TIMESTAMP,
                        FOREIGN KEY (demand_id) REFERENCES spare_parts_demands(id) ON DELETE CASCADE,
                        FOREIGN KEY (material_id) REFERENCES materials(id),
                        FOREIGN KEY (returned_by_id) REFERENCES users(id),
                        FOREIGN KEY (received_by_id) REFERENCES users(id),
                        INDEX idx_demand_id (demand_id),
                        INDEX idx_material_id (material_id),
                        INDEX idx_created_at (created_at)
                    )
                """)
                print("  → material_returns table created")
            except Exception as e:
                if "already exists" in str(e):
                    print("  → material_returns table already exists")
                else:
                    raise
            
            connection.commit()
            cursor.close()
            connection.close()
            
            print("\n✅ Database migration completed successfully!")
            print("\nNext steps:")
            print("1. Restart the Flask application")
            print("2. Test the new features")
            print("3. Check the application is running without errors")
            
        except Exception as e:
            connection.rollback()
            cursor.close()
            connection.close()
            print(f"\n❌ Migration failed: {str(e)}")
            raise

if __name__ == '__main__':
    run_migration()
