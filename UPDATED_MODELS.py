"""
Updated SQLAlchemy Models for Enhanced Database Schema
Sync these models with the migration script
"""

from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
from enum import Enum as PyEnum

db = SQLAlchemy()

# ============================================
# ENUMS
# ============================================

class UserRole(PyEnum):
    ADMIN = 'admin'
    SUPERVISOR = 'supervisor'
    TECHNICIAN = 'technician'
    STOCK_AGENT = 'stock_agent'

class DemandStatus(PyEnum):
    PENDING = 'pending'
    SUPERVISOR_REVIEW = 'supervisor_review'
    APPROVED_SUPERVISOR = 'approved_supervisor'
    STOCK_AGENT_REVIEW = 'stock_agent_review'
    APPROVED_STOCK_AGENT = 'approved_stock_agent'
    REJECTED = 'rejected'
    PARTIAL_ALLOCATED = 'partial_allocated'
    FULFILLED = 'fulfilled'

class ApprovalStatus(PyEnum):
    PENDING = 'pending'
    APPROVED = 'approved'
    REJECTED = 'rejected'
    PARTIAL = 'partial'

class Priority(PyEnum):
    LOW = 'low'
    MEDIUM = 'medium'
    HIGH = 'high'
    URGENT = 'urgent'

class MovementType(PyEnum):
    IN = 'in'
    OUT = 'out'
    ADJUSTMENT = 'adjustment'
    RETURN = 'return'

class PurchaseOrderStatus(PyEnum):
    DRAFT = 'draft'
    ORDERED = 'ordered'
    RECEIVED = 'received'
    CANCELLED = 'cancelled'

# ============================================
# MODELS
# ============================================

class Department(db.Model):
    __tablename__ = 'departments'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), unique=True, nullable=False)
    description = db.Column(db.Text)
    budget_allocated = db.Column(db.Numeric(15, 2), default=0)
    budget_remaining = db.Column(db.Numeric(15, 2), default=0)
    manager_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    manager = db.relationship('User', foreign_keys=[manager_id], backref='managed_departments')
    users = db.relationship('User', foreign_keys='User.department_id', backref='department')
    
    def __repr__(self):
        return f'<Department {self.name}>'

class User(db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.String(50), unique=True)  # NEW: TECH001, SUP001, etc
    username = db.Column(db.String(100), unique=True, nullable=False)
    password = db.Column(db.String(255), nullable=False)
    email = db.Column(db.String(100), unique=True, nullable=False)
    first_name = db.Column(db.String(100))
    last_name = db.Column(db.String(100))
    role = db.Column(db.String(20), nullable=False, default='technician')  # ENUM in DB
    department = db.Column(db.String(100))  # OLD: keeping for compatibility
    zone = db.Column(db.String(100))
    is_active = db.Column(db.Boolean, default=True)
    status = db.Column(db.String(50), default='active')  # NEW: active/inactive/on_leave
    supervisor_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)  # NEW: self-referential
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    supervisor = db.relationship('User', remote_side=[id], foreign_keys=[supervisor_id], backref='subordinates')
    demands = db.relationship('SparePartsDemand', foreign_keys='SparePartsDemand.requestor_id', backref='requestor')
    supervised_demands = db.relationship('SparePartsDemand', foreign_keys='SparePartsDemand.supervisor_id', backref='supervisor_approver')
    stock_agent_demands = db.relationship('SparePartsDemand', foreign_keys='SparePartsDemand.stock_agent_id', backref='stock_agent_approver')
    
    def __repr__(self):
        return f'<User {self.username}>'

class Supplier(db.Model):
    __tablename__ = 'suppliers'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(150), unique=True, nullable=False)
    contact_person = db.Column(db.String(100))
    email = db.Column(db.String(100))
    phone = db.Column(db.String(20))
    address = db.Column(db.Text)
    city = db.Column(db.String(50))
    country = db.Column(db.String(50))
    payment_terms = db.Column(db.String(100))
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    materials = db.relationship('Material', backref='supplier_ref')
    purchase_orders = db.relationship('PurchaseOrder', backref='supplier_ref')
    
    def __repr__(self):
        return f'<Supplier {self.name}>'

class StockLocation(db.Model):
    __tablename__ = 'stock_locations'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), unique=True, nullable=False)
    location_code = db.Column(db.String(50), unique=True)
    building = db.Column(db.String(50))
    floor = db.Column(db.Integer)
    warehouse_section = db.Column(db.String(100))
    capacity = db.Column(db.Integer)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f'<StockLocation {self.name}>'

class Material(db.Model):
    __tablename__ = 'materials'
    
    id = db.Column(db.Integer, primary_key=True)
    code = db.Column(db.String(50), unique=True, nullable=False)
    name = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text)
    category = db.Column(db.String(100))
    unit = db.Column(db.String(50))
    min_stock = db.Column(db.Integer, default=10)
    max_stock = db.Column(db.Integer, default=100)
    current_stock = db.Column(db.Integer, default=0)
    reorder_point = db.Column(db.Integer)
    unit_cost = db.Column(db.Numeric(10, 2))
    supplier = db.Column(db.String(100))  # OLD: keeping for compatibility
    supplier_id = db.Column(db.Integer, db.ForeignKey('suppliers.id'), nullable=True)  # NEW: FK reference
    last_restocked = db.Column(db.DateTime)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    demands = db.relationship('SparePartsDemand', backref='material')
    movements = db.relationship('StockMovement', backref='material')
    alerts = db.relationship('StockAlert', backref='material')
    
    def __repr__(self):
        return f'<Material {self.code}>'

class SparePartsDemand(db.Model):
    __tablename__ = 'spare_parts_demands'
    
    id = db.Column(db.Integer, primary_key=True)
    demand_number = db.Column(db.String(50), unique=True, nullable=False)
    maintenance_report_id = db.Column(db.Integer, db.ForeignKey('maintenance_reports.id'), nullable=True)
    requestor_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    material_id = db.Column(db.Integer, db.ForeignKey('materials.id'), nullable=False)
    quantity_requested = db.Column(db.Integer, nullable=False)
    priority = db.Column(db.String(20), default='medium')  # ENUM in DB
    reason = db.Column(db.Text)
    department_id = db.Column(db.Integer, db.ForeignKey('departments.id'), nullable=True)  # NEW
    
    # Supervisor Approval Fields
    supervisor_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)
    supervisor_approval = db.Column(db.String(50), default='pending')  # ENUM: pending, approved, rejected
    supervisor_approval_date = db.Column(db.DateTime)
    supervisor_notes = db.Column(db.Text)
    
    # Stock Agent Approval Fields
    stock_agent_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)
    stock_agent_approval = db.Column(db.String(50), default='pending')  # ENUM: pending, approved, rejected, partial
    stock_agent_approval_date = db.Column(db.DateTime)
    quantity_allocated = db.Column(db.Integer)
    stock_agent_notes = db.Column(db.Text)
    
    # Return Tracking
    quantity_returned = db.Column(db.Integer, default=0)
    return_date = db.Column(db.DateTime)
    return_notes = db.Column(db.Text)
    
    # Status and Timeline
    demand_status = db.Column(db.String(50), default='pending')  # ENUM: complex status
    fulfilled_date = db.Column(db.DateTime)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    department = db.relationship('Department', backref='demands')
    approvals = db.relationship('DemandApproval', backref='demand', cascade='all, delete-orphan')
    returns = db.relationship('MaterialReturn', backref='demand')
    
    def __repr__(self):
        return f'<SparePartsDemand {self.demand_number}>'

class DemandApproval(db.Model):
    __tablename__ = 'demand_approvals'
    
    id = db.Column(db.Integer, primary_key=True)
    demand_id = db.Column(db.Integer, db.ForeignKey('spare_parts_demands.id'), nullable=False)
    approval_level = db.Column(db.String(50), nullable=False)  # supervisor, stock_agent, admin
    approver_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    approval_status = db.Column(db.String(50), default='pending')  # ENUM
    approval_date = db.Column(db.DateTime)
    notes = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    approver = db.relationship('User', backref='approvals')
    
    def __repr__(self):
        return f'<DemandApproval {self.approval_level}>'

class StockMovement(db.Model):
    __tablename__ = 'stock_movements'
    
    id = db.Column(db.Integer, primary_key=True)
    material_id = db.Column(db.Integer, db.ForeignKey('materials.id'), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    movement_type = db.Column(db.String(50), nullable=False)  # ENUM: in, out, adjustment, return
    quantity = db.Column(db.Integer, nullable=False)
    reference_id = db.Column(db.String(100))  # Links to demand_id, PO id, etc
    notes = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user = db.relationship('User', backref='stock_movements')
    
    def __repr__(self):
        return f'<StockMovement {self.movement_type}>'

class StockAlert(db.Model):
    __tablename__ = 'stock_alerts'
    
    id = db.Column(db.Integer, primary_key=True)
    material_id = db.Column(db.Integer, db.ForeignKey('materials.id'), nullable=False)
    alert_type = db.Column(db.String(50))  # low_stock, overstock, expiring
    alert_message = db.Column(db.Text)
    is_read = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f'<StockAlert {self.alert_type}>'

class PurchaseOrder(db.Model):
    __tablename__ = 'purchase_orders'
    
    id = db.Column(db.Integer, primary_key=True)
    po_number = db.Column(db.String(50), unique=True, nullable=False)
    supplier_id = db.Column(db.Integer, db.ForeignKey('suppliers.id'), nullable=False)
    material_id = db.Column(db.Integer, db.ForeignKey('materials.id'), nullable=False)
    quantity_ordered = db.Column(db.Integer, nullable=False)
    unit_price = db.Column(db.Numeric(10, 2))
    total_cost = db.Column(db.Numeric(15, 2))
    order_date = db.Column(db.DateTime, default=datetime.utcnow)
    expected_delivery_date = db.Column(db.Date)
    actual_delivery_date = db.Column(db.Date)
    status = db.Column(db.String(50), default='draft')  # ENUM: draft, ordered, received, cancelled
    notes = db.Column(db.Text)
    created_by_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    material = db.relationship('Material', backref='purchase_orders')
    created_by = db.relationship('User', backref='created_purchase_orders')
    
    def __repr__(self):
        return f'<PurchaseOrder {self.po_number}>'

class MaterialReturn(db.Model):
    __tablename__ = 'material_returns'
    
    id = db.Column(db.Integer, primary_key=True)
    demand_id = db.Column(db.Integer, db.ForeignKey('spare_parts_demands.id'), nullable=False)
    material_id = db.Column(db.Integer, db.ForeignKey('materials.id'), nullable=False)
    quantity_returned = db.Column(db.Integer, nullable=False)
    return_condition = db.Column(db.String(100))  # unused, damaged, partial_used
    reason_for_return = db.Column(db.Text)
    returned_by_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    received_by_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    returned_by = db.relationship('User', foreign_keys=[returned_by_id], backref='materials_returned')
    received_by = db.relationship('User', foreign_keys=[received_by_id], backref='materials_received')
    
    def __repr__(self):
        return f'<MaterialReturn {self.id}>'
