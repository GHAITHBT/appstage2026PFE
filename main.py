"""
Maintenance Management System
Main Application Entry Point
"""

import os
from app import create_app, db
from app.models import User, Material, Machine, MaintenanceSchedule, MaintenanceReport
from app.models import SparePartsDemand, StockMovement, StockAlert, MaterialReturn
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Create Flask app
app = create_app(os.getenv('FLASK_ENV', 'development'))

@app.shell_context_processor
def make_shell_context():
    """Add database models to shell context"""
    return {
        'db': db,
        'User': User,
        'Material': Material,
        'Machine': Machine,
        'MaintenanceSchedule': MaintenanceSchedule,
        'MaintenanceReport': MaintenanceReport,
        'SparePartsDemand': SparePartsDemand,
        'StockMovement': StockMovement,
        'StockAlert': StockAlert,
        'MaterialReturn': MaterialReturn,
    }

@app.cli.command()
def init_db():
    """Initialize the database"""
    db.create_all()
    print('Database initialized!')

@app.cli.command()
def seed_db():
    """Seed the database with sample data"""
    from werkzeug.security import generate_password_hash
    
    # Create admin user if not exists
    admin = User.query.filter_by(username='admin').first()
    if not admin:
        admin = User(
            username='admin',
            password=generate_password_hash('admin123'),
            email='admin@sumitomo.com',
            first_name='Admin',
            last_name='User',
            role='admin',
            is_active=True
        )
        db.session.add(admin)
    
    # Create sample supervisor
    supervisor = User.query.filter_by(username='supervisor').first()
    if not supervisor:
        supervisor = User(
            username='supervisor',
            password=generate_password_hash('sup123'),
            email='supervisor@sumitomo.com',
            first_name='John',
            last_name='Supervisor',
            role='supervisor',
            department='Production',
            is_active=True
        )
        db.session.add(supervisor)
    
    # Create sample technician
    technician = User.query.filter_by(username='technician').first()
    if not technician:
        technician = User(
            username='technician',
            password=generate_password_hash('tech123'),
            email='technician@sumitomo.com',
            first_name='Jane',
            last_name='Technician',
            role='technician',
            department='Maintenance',
            is_active=True
        )
        db.session.add(technician)
    
    # Create sample stock agent
    stock_agent = User.query.filter_by(username='stock_agent').first()
    if not stock_agent:
        stock_agent = User(
            username='stock_agent',
            password=generate_password_hash('stock123'),
            email='stock@sumitomo.com',
            first_name='Mike',
            last_name='StockAgent',
            role='stock_agent',
            department='Stock',
            is_active=True
        )
        db.session.add(stock_agent)
    
    db.session.commit()
    print('Database seeded with sample users!')

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    
    app.run(
        host='0.0.0.0',
        port=5000,
        debug=True
    )
