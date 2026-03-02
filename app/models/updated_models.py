"""
Updated Models for Stock Management System
Includes Department, Supervisor tracking, and comprehensive audit trails
"""

from flask_sqlalchemy import SQLAlchemy
from DateTime import datetime, timedelta
from werkzeug.security import generate_password_hash, check_password_hash
from enum import Enum

db = SQLAlchemy()

# ============================================
# ENUMS
# ============================================
class UserRole(Enum):
    ADMIN = 'admin'
    SUPERVISOR = 'supervisor'
    TECHNICIAN = 'technician'
    STOCK_AGENT = 'stock_agent'
    OPERATOR = 'operator'

class UserStatus(Enum):
    ACTIVE = 'active'
    INACTIVE = 'inactive'
    SUSPENDED = 'suspended'

class DemandStatus(Enum):
    PENDING = 'pending'
    SUPERVISOR_REVIEW = 'supervisor_review'
    APPROVED_SUPERVISOR = 'approved_supervisor'
    STOCK_AGENT_REVIEW = 'stock_agent_review'
    APPROVED_STOCK_AGENT = 'approved_stock_agent'
    FULFILLED = 'fulfilled'
    REJECTED = 'rejected'
    CANCELLED = 'cancelled'

class ApprovalStatus(Enum):
    APPROVED = 'approved'
    REJECTED = 'rejected'
    PENDING = 'pending'

class ApprovalLevel(Enum):
    SUPERVISOR = 'supervisor'
    STOCK_AGENT = 'stock_agent'
    ADMIN = 'admin'

class MovementType(Enum):
    RECEIPT = 'receipt'
    ISSUE = 'issue'
    ADJUSTMENT = 'adjustment'
    RETURN = 'return'
    TRANSFER = 'transfer'
    DAMAGE = 'damage'
    EXPIRED = 'expired'

class AlertType(Enum):
    LOW_STOCK = 'low_stock'
    OVERSTOCK = 'overstock'
    EXPIRED_SOON = 'expired_soon'
    DAMAGED = 'damaged'
    MISSING = 'missing'

class AlertStatus(Enum):
    ACTIVE = 'active'
    ACKNOWLEDGED = 'acknowledged'
    RESOLVED = 'resolved'

class PriorityLevel(Enum):
    LOW = 'low'
    MEDIUM = 'medium'
    HIGH = 'high'
    URGENT = 'urgent'

# ============================================
# DEPARTMENT MODEL
# ============================================
class Department(db.Model):
    __tablename__ = 'departments'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), unique=True, nullable=False)
    description = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    users = db.relationship('User', backref='department', lazy='dynamic', foreign_keys='User.department_id')
    demands = db.relationship('SparePartsDemand', backref='department', lazy='dynamic')
    
    def __repr__(self):
        return f'<Department {self.name}>'

# ============================================
# USER MODEL (Updated with Department & Supervisor)
# ============================================
class User(db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.String(50), unique=True, nullable=False)
    full_name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(100), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    role = db.Column(db.String(20), default='operator', nullable=False)
    department_id = db.Column(db.Integer, db.ForeignKey('departments.id'), nullable=False)
    supervisor_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)
    status = db.Column(db.String(20), default='active', nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Self-referential relationship for supervisor
    subordinates = db.relationship('User', remote_side=[id], backref='supervisor', lazy='dynamic')
    
    # Relationships
    demands = db.relationship('SparePartsDemand', backref='requester', lazy='dynamic', foreign_keys='SparePartsDemand.requested_by_id')
    approvals = db.relationship('DemandApproval', backref='approver', lazy='dynamic')
    stock_movements_initiated = db.relationship('StockMovement', backref='initiator', lazy='dynamic', foreign_keys='StockMovement.initiated_by_id')
    stock_movements_approved = db.relationship('StockMovement', backref='approver', lazy='dynamic', foreign_keys='StockMovement.approved_by_id')
    purchase_orders = db.relationship('PurchaseOrder', backref='creator', lazy='dynamic')
    
    def set_password(self, password):
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)
    
    def __repr__(self):
        return f'<User {self.user_id}: {self.full_name}>'

# ============================================
# SUPPLIER MODEL
# ============================================
class Supplier(db.Model):
    __tablename__ = 'suppliers'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(150), unique=True, nullable=False)
    code = db.Column(db.String(50), unique=True)
    contact_person = db.Column(db.String(100))
    email = db.Column(db.String(100))
    phone = db.Column(db.String(20))
    address = db.Column(db.Text)
    city = db.Column(db.String(50))
    country = db.Column(db.String(50))
    payment_terms = db.Column(db.String(100))
    status = db.Column(db.String(20), default='active')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    materials = db.relationship('Material', backref='supplier', lazy='dynamic')
    purchase_orders = db.relationship('PurchaseOrder', backref='supplier', lazy='dynamic')
    
    def __repr__(self):
        return f'<Supplier {self.name}>'

# ============================================
# MATERIAL/PRODUCT MODEL
# ============================================
class Material(db.Model):
    __tablename__ = 'materials'
    
    id = db.Column(db.Integer, primary_key=True)
    reference = db.Column(db.String(50), unique=True, nullable=False)
    designation = db.Column(db.String(255), nullable=False)
    code_frs = db.Column(db.String(50))
    category = db.Column(db.String(100))
    supplier_id = db.Column(db.Integer, db.ForeignKey('suppliers.id'), nullable=False)
    unit_of_measure = db.Column(db.String(20), default='PCS')
    min_quantity = db.Column(db.Integer, default=1)
    max_quantity = db.Column(db.Integer, default=100)
    reorder_quantity = db.Column(db.Integer, default=0)
    unit_price_eur = db.Column(db.Float, nullable=False)
    status = db.Column(db.String(20), default='active')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    inventory = db.relationship('Inventory', backref='material', lazy='dynamic', cascade='all, delete-orphan')
    demands = db.relationship('SparePartsDemand', backref='material', lazy='dynamic')
    purchase_orders = db.relationship('PurchaseOrder', backref='material', lazy='dynamic')
    stock_movements = db.relationship('StockMovement', backref='material', lazy='dynamic')
    alerts = db.relationship('StockAlert', backref='material', lazy='dynamic', cascade='all, delete-orphan')
    
    def get_total_stock(self):
        """Get total stock across all locations"""
        inv_items = self.inventory.all()
        return sum([item.quantity_on_hand for item in inv_items])
    
    def get_total_available(self):
        """Get total available stock (on hand - reserved)"""
        inv_items = self.inventory.all()
        return sum([item.quantity_available for item in inv_items])
    
    def is_low_stock(self):
        """Check if material is below minimum quantity"""
        return self.get_total_on_hand() < self.min_quantity
    
    def __repr__(self):
        return f'<Material {self.reference}: {self.designation[:30]}>'

# ============================================
# STOCK LOCATION MODEL
# ============================================
class StockLocation(db.Model):
    __tablename__ = 'stock_locations'
    
    id = db.Column(db.Integer, primary_key=True)
    location_code = db.Column(db.String(20), unique=True, nullable=False)
    location_name = db.Column(db.String(100), nullable=False)
    warehouse_zone = db.Column(db.String(50))
    capacity = db.Column(db.Integer)
    current_usage = db.Column(db.Integer, default=0)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    inventory = db.relationship('Inventory', backref='location', lazy='dynamic')
    stock_movements = db.relationship('StockMovement', backref='location', lazy='dynamic')
    
    def __repr__(self):
        return f'<StockLocation {self.location_code}>'

# ============================================
# INVENTORY MODEL
# ============================================
class Inventory(db.Model):
    __tablename__ = 'inventory'
    
    id = db.Column(db.Integer, primary_key=True)
    material_id = db.Column(db.Integer, db.ForeignKey('materials.id'), nullable=False)
    location_id = db.Column(db.Integer, db.ForeignKey('stock_locations.id'), nullable=False)
    quantity_on_hand = db.Column(db.Integer, default=0)
    quantity_reserved = db.Column(db.Integer, default=0)
    status = db.Column(db.String(20), default='good')
    last_count_date = db.Column(db.DateTime)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    @property
    def quantity_available(self):
        return self.quantity_on_hand - self.quantity_reserved
    
    def __repr__(self):
        return f'<Inventory {self.material.reference} @ {self.location.location_code}>'

# ============================================
# PURCHASE ORDER MODEL
# ============================================
class PurchaseOrder(db.Model):
    __tablename__ = 'purchase_orders'
    
    id = db.Column(db.Integer, primary_key=True)
    po_number = db.Column(db.String(50), unique=True, nullable=False)
    material_id = db.Column(db.Integer, db.ForeignKey('materials.id'), nullable=False)
    supplier_id = db.Column(db.Integer, db.ForeignKey('suppliers.id'), nullable=False)
    quantity_ordered = db.Column(db.Integer, nullable=False)
    unit_price_eur = db.Column(db.Float, nullable=False)
    order_date = db.Column(db.Date, nullable=False)
    expected_delivery = db.Column(db.Date)
    actual_delivery = db.Column(db.Date)
    status = db.Column(db.String(20), default='pending')
    created_by_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    @property
    def total_eur(self):
        return self.quantity_ordered * self.unit_price_eur
    
    def __repr__(self):
        return f'<PurchaseOrder {self.po_number}>'

# ============================================
# SPARE PARTS DEMAND MODEL
# ============================================
class SparePartsDemand(db.Model):
    __tablename__ = 'spare_parts_demands'
    
    id = db.Column(db.Integer, primary_key=True)
    demand_number = db.Column(db.String(50), unique=True, nullable=False)
    material_id = db.Column(db.Integer, db.ForeignKey('materials.id'), nullable=False)
    quantity_requested = db.Column(db.Integer, nullable=False)
    priority = db.Column(db.String(20), default='medium')
    requested_by_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    department_id = db.Column(db.Integer, db.ForeignKey('departments.id'), nullable=False)
    request_date = db.Column(db.DateTime, default=datetime.utcnow)
    required_by_date = db.Column(db.Date)
    demand_status = db.Column(db.String(30), default='pending')
    notes = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    approvals = db.relationship('DemandApproval', backref='demand', lazy='dynamic', cascade='all, delete-orphan')
    
    @property
    def progress_percentage(self):
        """Calculate demand fulfillment progress"""
        if not self.approvals.filter_by(approval_status='approved').count():
            return 0
        return min(100, int((self.approvals.filter_by(approval_status='approved').count() / max(1, self.approvals.count())) * 100))
    
    def __repr__(self):
        return f'<SparePartsDemand {self.demand_number}>'

# ============================================
# DEMAND APPROVAL HISTORY MODEL
# ============================================
class DemandApproval(db.Model):
    __tablename__ = 'demand_approvals'
    
    id = db.Column(db.Integer, primary_key=True)
    demand_id = db.Column(db.Integer, db.ForeignKey('spare_parts_demands.id'), nullable=False)
    approval_level = db.Column(db.String(20), nullable=False)  # supervisor, stock_agent, admin
    approved_by_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    approval_status = db.Column(db.String(20), default='pending')
    approval_date = db.Column(db.DateTime, default=datetime.utcnow)
    rejection_reason = db.Column(db.Text)
    notes = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def __repr__(self):
        return f'<DemandApproval Demand {self.demand_id} - {self.approval_level} {self.approval_status}>'

# ============================================
# STOCK MOVEMENTS HISTORY MODEL
# ============================================
class StockMovement(db.Model):
    __tablename__ = 'stock_movements'
    
    id = db.Column(db.Integer, primary_key=True)
    material_id = db.Column(db.Integer, db.ForeignKey('materials.id'), nullable=False)
    location_id = db.Column(db.Integer, db.ForeignKey('stock_locations.id'), nullable=False)
    movement_type = db.Column(db.String(20), nullable=False)  # receipt, issue, adjustment, etc
    quantity_change = db.Column(db.Integer, nullable=False)
    reference_number = db.Column(db.String(100))
    reference_type = db.Column(db.String(50))  # purchase_order, demand, etc
    initiated_by_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    approved_by_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    notes = db.Column(db.Text)
    movement_date = db.Column(db.DateTime, default=datetime.utcnow)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def __repr__(self):
        return f'<StockMovement {self.reference_number} - {self.movement_type}>'

# ============================================
# STOCK ALERT MODEL
# ============================================
class StockAlert(db.Model):
    __tablename__ = 'stock_alerts'
    
    id = db.Column(db.Integer, primary_key=True)
    material_id = db.Column(db.Integer, db.ForeignKey('materials.id'), nullable=False)
    alert_type = db.Column(db.String(20), nullable=False)  # low_stock, overstock, etc
    alert_status = db.Column(db.String(20), default='active')
    description = db.Column(db.Text)
    acknowledged_by_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    acknowledged_date = db.Column(db.DateTime)
    resolution_notes = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f'<StockAlert {self.alert_type} - Material {self.material_id}>'
