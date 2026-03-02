from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
from enum import Enum

db = SQLAlchemy()

# Enums
class UserRole(Enum):
    ADMIN = 'admin'
    SUPERVISOR = 'supervisor'
    TECHNICIAN = 'technician'
    STOCK_AGENT = 'stock_agent'

class MaintenanceStatus(Enum):
    SCHEDULED = 'scheduled'
    IN_PROGRESS = 'in_progress'
    COMPLETED = 'completed'
    CANCELLED = 'cancelled'
    OVERDUE = 'overdue'

class DemandStatus(Enum):
    PENDING = 'pending'
    SUPERVISOR_REVIEW = 'supervisor_review'
    APPROVED_SUPERVISOR = 'approved_supervisor'
    STOCK_AGENT_REVIEW = 'stock_agent_review'
    APPROVED_STOCK_AGENT = 'approved_stock_agent'
    REJECTED = 'rejected'
    PARTIAL_ALLOCATED = 'partial_allocated'
    FULFILLED = 'fulfilled'

class ApprovalStatus(Enum):
    PENDING = 'pending'
    APPROVED = 'approved'
    REJECTED = 'rejected'
    PARTIAL = 'partial'

# Models

class User(db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.String(50), unique=True)
    username = db.Column(db.String(100), unique=True, nullable=False, index=True)
    password = db.Column(db.String(255), nullable=False)
    email = db.Column(db.String(100), unique=True, nullable=False)
    first_name = db.Column(db.String(100))
    last_name = db.Column(db.String(100))
    role = db.Column(db.String(50), nullable=False, default='technician', index=True)
    department = db.Column(db.String(100))
    zone = db.Column(db.String(100))  # Work zone for technicians
    is_active = db.Column(db.Boolean, default=True, index=True)
    status = db.Column(db.String(50), default='active')
    supervisor_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    supervisor = db.relationship('User', remote_side=[id], backref='subordinates', foreign_keys=[supervisor_id])
    maintenance_schedules = db.relationship('MaintenanceSchedule', backref='supervisor', foreign_keys='MaintenanceSchedule.assigned_supervisor_id')
    maintenance_reports = db.relationship('MaintenanceReport', backref='technician', foreign_keys='MaintenanceReport.technician_id')
    demands_created = db.relationship('SparePartsDemand', backref='requestor', foreign_keys='SparePartsDemand.requestor_id')
    demands_supervised = db.relationship('SparePartsDemand', backref='supervisor_user', foreign_keys='SparePartsDemand.supervisor_id')
    demands_stock = db.relationship('SparePartsDemand', backref='stock_agent_user', foreign_keys='SparePartsDemand.stock_agent_id')
    
    def __repr__(self):
        return f'<User {self.username}>'
    
    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}"

class Zone(db.Model):
    __tablename__ = 'zones'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), unique=True, nullable=False, index=True)
    description = db.Column(db.Text)
    created_by_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    created_by = db.relationship('User', backref='zones_created', foreign_keys=[created_by_id])
    
    def __repr__(self):
        return f'<Zone {self.name}>'

class Supplier(db.Model):
    __tablename__ = 'suppliers'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(150), unique=True, nullable=False, index=True)
    contact_person = db.Column(db.String(100))
    email = db.Column(db.String(100))
    phone = db.Column(db.String(20))
    address = db.Column(db.Text)
    city = db.Column(db.String(50))
    country = db.Column(db.String(50))
    payment_terms = db.Column(db.String(100))
    is_active = db.Column(db.Boolean, default=True, index=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f'<Supplier {self.name}>'

class Department(db.Model):
    __tablename__ = 'departments'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), unique=True, nullable=False, index=True)
    description = db.Column(db.Text)
    budget_allocated = db.Column(db.Numeric(15, 2), default=0)
    budget_remaining = db.Column(db.Numeric(15, 2), default=0)
    manager_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    manager = db.relationship('User', backref='managed_departments', foreign_keys=[manager_id])
    
    def __repr__(self):
        return f'<Department {self.name}>'

class StockLocation(db.Model):
    __tablename__ = 'stock_locations'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), unique=True, nullable=False)
    location_code = db.Column(db.String(50), unique=True, nullable=True)
    building = db.Column(db.String(50))
    floor = db.Column(db.Integer)
    warehouse_section = db.Column(db.String(100))
    capacity = db.Column(db.Integer)
    is_active = db.Column(db.Boolean, default=True, index=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f'<StockLocation {self.name}>'

class Material(db.Model):
    __tablename__ = 'materials'
    
    id = db.Column(db.Integer, primary_key=True)
    code = db.Column(db.String(50), unique=True, nullable=False, index=True)
    name = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text)
    category = db.Column(db.String(100), index=True)
    unit = db.Column(db.String(50))
    min_stock = db.Column(db.Integer, default=10)
    max_stock = db.Column(db.Integer, default=100)
    current_stock = db.Column(db.Integer, default=0, index=True)
    reorder_point = db.Column(db.Integer)
    unit_cost = db.Column(db.Float)
    supplier = db.Column(db.String(100))
    supplier_id = db.Column(db.Integer, db.ForeignKey('suppliers.id'), nullable=True)
    last_restocked = db.Column(db.DateTime)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    supplier_obj = db.relationship('Supplier', backref='materials')
    demands = db.relationship('SparePartsDemand', backref='material')
    movements = db.relationship('StockMovement', backref='material')
    alerts = db.relationship('StockAlert', backref='material', cascade='all, delete-orphan')
    
    def __repr__(self):
        return f'<Material {self.code}>'
    
    @property
    def stock_status(self):
        if self.current_stock <= self.min_stock:
            return 'critical'
        elif (self.reorder_point and self.current_stock <= self.reorder_point) or self.current_stock > self.max_stock:
            return 'warning'
        return 'normal'

class Machine(db.Model):
    __tablename__ = 'machines'
    
    id = db.Column(db.Integer, primary_key=True)
    machine_code = db.Column(db.String(50), unique=True, nullable=False, index=True)
    name = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text)
    location = db.Column(db.String(200))
    department = db.Column(db.String(100), index=True)
    model = db.Column(db.String(100))
    manufacturer = db.Column(db.String(100))
    purchase_date = db.Column(db.Date)
    installation_date = db.Column(db.Date)
    status = db.Column(db.String(50), default='active', index=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    maintenance_schedules = db.relationship('MaintenanceSchedule', backref='machine', cascade='all, delete-orphan')
    
    def __repr__(self):
        return f'<Machine {self.machine_code}>'

class MaintenanceSchedule(db.Model):
    __tablename__ = 'maintenance_schedules'
    
    id = db.Column(db.Integer, primary_key=True)
    machine_id = db.Column(db.Integer, db.ForeignKey('machines.id', ondelete='CASCADE'), nullable=False, index=True)
    schedule_type = db.Column(db.String(50))
    frequency_days = db.Column(db.Integer)
    scheduled_date = db.Column(db.Date, nullable=False, index=True)
    description = db.Column(db.Text)
    estimated_duration_hours = db.Column(db.Integer)
    assigned_supervisor_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    status = db.Column(db.String(50), default='scheduled', index=True)
    priority = db.Column(db.String(50), default='medium')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    maintenance_reports = db.relationship('MaintenanceReport', backref='schedule', cascade='all, delete-orphan')
    
    def __repr__(self):
        return f'<MaintenanceSchedule {self.id}>'

class MaintenanceReport(db.Model):
    __tablename__ = 'maintenance_reports'
    
    id = db.Column(db.Integer, primary_key=True)
    schedule_id = db.Column(db.Integer, db.ForeignKey('maintenance_schedules.id', ondelete='CASCADE'), nullable=False)
    technician_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    machine_name = db.Column(db.String(200))  # Cached machine name for easier access
    actual_start_time = db.Column(db.DateTime)
    actual_end_time = db.Column(db.DateTime)
    actual_duration_hours = db.Column(db.Float)
    work_description = db.Column(db.Text)
    findings = db.Column(db.Text)
    actions_taken = db.Column(db.Text)
    issues_found = db.Column(db.Boolean, default=False)
    issue_description = db.Column(db.Text)
    components_replaced = db.Column(db.Text)
    next_maintenance_recommendation = db.Column(db.Text)
    report_type = db.Column(db.String(50), default='standard')  # 'standard' or 'detailed'
    report_status = db.Column(db.String(50), default='draft')  # draft, submitted, approved, rejected
    technician_zone = db.Column(db.String(100))  # Zone where technician worked
    machine_condition = db.Column(db.String(50))  # Before maintenance condition
    machine_condition_after = db.Column(db.String(50))  # After maintenance condition
    environmental_conditions = db.Column(db.Text)  # Environmental notes
    safety_observations = db.Column(db.Text)  # Safety observations
    tools_used = db.Column(db.Text)  # Tools used during maintenance
    
    # Supervisor approval fields
    supervisor_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)
    supervisor_approval_status = db.Column(db.String(50), default='pending')  # pending, approved, rejected
    supervisor_approval_date = db.Column(db.DateTime)
    supervisor_notes = db.Column(db.Text)
    
    # Checklist data (JSON format for flexibility)
    checklist_data = db.Column(db.Text)  # JSON string with checklist items and results
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    demands = db.relationship('SparePartsDemand', backref='maintenance_report')
    
    def __repr__(self):
        return f'<MaintenanceReport {self.id}>'

class SparePartsDemand(db.Model):
    __tablename__ = 'spare_parts_demands'
    
    id = db.Column(db.Integer, primary_key=True)
    demand_number = db.Column(db.String(50), unique=True, nullable=False, index=True)
    maintenance_report_id = db.Column(db.Integer, db.ForeignKey('maintenance_reports.id', ondelete='SET NULL'))
    requestor_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    material_id = db.Column(db.Integer, db.ForeignKey('materials.id'), nullable=False, index=True)
    quantity_requested = db.Column(db.Integer, nullable=False)
    priority = db.Column(db.String(50), default='medium')
    reason = db.Column(db.Text)
    
    supervisor_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    supervisor_approval = db.Column(db.String(50), default='pending')
    supervisor_approval_date = db.Column(db.DateTime)
    supervisor_notes = db.Column(db.Text)
    
    stock_agent_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    stock_agent_approval = db.Column(db.String(50), default='pending')
    stock_agent_approval_date = db.Column(db.DateTime)
    quantity_allocated = db.Column(db.Integer)
    stock_agent_notes = db.Column(db.Text)
    
    # Return tracking
    quantity_returned = db.Column(db.Integer, default=0)  # Material returned to stock
    return_date = db.Column(db.DateTime)
    return_notes = db.Column(db.Text)
    
    demand_status = db.Column(db.String(50), default='pending', index=True)
    fulfilled_date = db.Column(db.DateTime)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, index=True)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f'<SparePartsDemand {self.demand_number}>'
    
    @property
    def progress_percentage(self):
        if self.demand_status == 'pending':
            return 10
        elif self.demand_status == 'supervisor_review':
            return 20
        elif self.demand_status == 'approved_supervisor':
            return 40
        elif self.demand_status == 'stock_agent_review':
            return 60
        elif self.demand_status == 'approved_stock_agent':
            return 80
        elif self.demand_status == 'fulfilled':
            return 100
        return 0

class StockMovement(db.Model):
    __tablename__ = 'stock_movements'
    
    id = db.Column(db.Integer, primary_key=True)
    material_id = db.Column(db.Integer, db.ForeignKey('materials.id', ondelete='CASCADE'), nullable=False, index=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    movement_type = db.Column(db.String(50), nullable=False)  # 'in', 'out', 'allocated', 'returned', etc.
    quantity = db.Column(db.Integer, nullable=False)
    reference_id = db.Column(db.String(100))
    notes = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, index=True)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user = db.relationship('User', backref='stock_movements')
    
    def __repr__(self):
        return f'<StockMovement {self.id}>'

class StockAlert(db.Model):
    __tablename__ = 'stock_alerts'
    
    id = db.Column(db.Integer, primary_key=True)
    material_id = db.Column(db.Integer, db.ForeignKey('materials.id', ondelete='CASCADE'), nullable=False, index=True)
    alert_type = db.Column(db.String(50))  # 'low_stock', 'overstock', 'critical'
    alert_message = db.Column(db.Text)
    is_read = db.Column(db.Boolean, default=False, index=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, index=True)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f'<StockAlert {self.id}>'

class MaintenanceTemplate(db.Model):
    __tablename__ = 'maintenance_templates'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(150))
    description = db.Column(db.Text)
    frequency = db.Column(db.Integer)  # frequency in days
    created_by = db.Column(db.Integer, db.ForeignKey('users.id'))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    creator = db.relationship('User', backref='maintenance_templates', foreign_keys=[created_by])
    
    def __repr__(self):
        return f'<MaintenanceTemplate {self.name}>'

class DashboardKPI(db.Model):
    __tablename__ = 'dashboard_kpis'
    
    id = db.Column(db.Integer, primary_key=True)
    kpi_name = db.Column(db.String(100))
    kpi_value = db.Column(db.Integer)
    kpi_date = db.Column(db.Date, index=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f'<DashboardKPI {self.kpi_name}>'
class MaterialReturn(db.Model):
    __tablename__ = 'material_returns'
    
    id = db.Column(db.Integer, primary_key=True)
    demand_id = db.Column(db.Integer, db.ForeignKey('spare_parts_demands.id', ondelete='CASCADE'), nullable=False, index=True)
    material_id = db.Column(db.Integer, db.ForeignKey('materials.id'), nullable=False)
    quantity_returned = db.Column(db.Integer, nullable=False)
    return_condition = db.Column(db.String(100))
    reason_for_return = db.Column(db.Text)
    returned_by_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    received_by_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    return_status = db.Column(db.String(50), default='pending', index=True)  # pending, accepted, rejected
    created_at = db.Column(db.DateTime, default=datetime.utcnow, index=True)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    returned_by = db.relationship('User', foreign_keys=[returned_by_id], backref='materials_returned')
    received_by = db.relationship('User', foreign_keys=[received_by_id], backref='materials_received')
    demand = db.relationship('SparePartsDemand')
    
    def __repr__(self):
        return f'<MaterialReturn {self.id}>'

class PurchaseOrder(db.Model):
    __tablename__ = 'purchase_orders'
    
    id = db.Column(db.Integer, primary_key=True)
    po_number = db.Column(db.String(50), unique=True, nullable=False, index=True)
    supplier_id = db.Column(db.Integer, db.ForeignKey('suppliers.id'), nullable=False)
    material_id = db.Column(db.Integer, db.ForeignKey('materials.id'), nullable=False)
    quantity_ordered = db.Column(db.Integer, nullable=False)
    unit_price = db.Column(db.Numeric(10, 2))
    total_cost = db.Column(db.Numeric(15, 2))
    order_date = db.Column(db.DateTime, default=datetime.utcnow)
    expected_delivery_date = db.Column(db.Date)
    actual_delivery_date = db.Column(db.Date)
    status = db.Column(db.String(50), default='draft', index=True)  # 'draft', 'ordered', 'received', 'cancelled'
    notes = db.Column(db.Text)
    created_by_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    supplier = db.relationship('Supplier', backref='purchase_orders')
    material = db.relationship('Material', backref='purchase_orders')
    created_by = db.relationship('User', backref='created_purchase_orders', foreign_keys=[created_by_id])
    
    def __repr__(self):
        return f'<PurchaseOrder {self.po_number}>'

class DemandApproval(db.Model):
    __tablename__ = 'demand_approvals'
    
    id = db.Column(db.Integer, primary_key=True)
    demand_id = db.Column(db.Integer, db.ForeignKey('spare_parts_demands.id', ondelete='CASCADE'), nullable=False, index=True)
    approval_level = db.Column(db.String(50), nullable=False)  # 'supervisor', 'stock_agent'
    approver_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    approval_status = db.Column(db.String(50), default='pending')  # 'pending', 'approved', 'rejected'
    approval_date = db.Column(db.DateTime)
    notes = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    demand = db.relationship('SparePartsDemand', backref='approvals')
    approver = db.relationship('User', backref='approvals_made', foreign_keys=[approver_id])
    
    def __repr__(self):
        return f'<DemandApproval {self.id}>'