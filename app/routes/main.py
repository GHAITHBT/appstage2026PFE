from flask import Blueprint, render_template, request, redirect, url_for, session, flash
from app.models import db, Material, Machine, MaintenanceSchedule, SparePartsDemand, StockAlert, User, MaterialReturn, Zone, MaintenanceReport
from app.routes.auth import login_required, role_required
from datetime import datetime, timedelta

main_bp = Blueprint('main', __name__)

@main_bp.route('/')
def index():
    if 'user_id' in session:
        user = User.query.get(session['user_id'])
        # Redirect based on role
        if user.role in ['admin', 'supervisor']:
            return redirect(url_for('main.dashboard'))
        else:
            # Technician and stock agents go to stock inventory
            return redirect(url_for('stock.inventory'))
    return redirect(url_for('auth.login'))

@main_bp.route('/dashboard')
@login_required
def dashboard():
    user = User.query.get(session['user_id'])
    
    # Define all available modules with role-based access
    modules = {
        'stock': {
            'title': 'Stock Management',
            'icon': 'box',
            'description': 'Manage inventory and materials',
            'url': 'stock.inventory',
            'roles': ['admin', 'stock_agent', 'supervisor', 'technician'],
            'color': '#3b82f6'
        },
        'maintenance': {
            'title': 'Maintenance Schedules',
            'icon': 'tools',
            'description': 'Schedule and track maintenance',
            'url': 'maintenance.schedules',
            'roles': ['admin', 'supervisor', 'technician'],
            'color': '#10b981'
        },
        'demands': {
            'title': 'Spare Parts Demands',
            'icon': 'cart-check',
            'description': 'Request and approve parts',
            'url': 'demands.list_demands',
            'roles': ['admin', 'supervisor', 'technician', 'stock_agent'],
            'color': '#f59e0b'
        },
        'alerts': {
            'title': 'Stock Alerts',
            'icon': 'bell',
            'description': 'View stock level alerts',
            'url': 'stock.stock_alerts',
            'roles': ['admin', 'stock_agent', 'supervisor'],
            'color': '#ef4444'
        },
        'materials': {
            'title': 'Add Material',
            'icon': 'plus-circle',
            'description': 'Add new inventory items',
            'url': 'stock.add_material',
            'roles': ['admin', 'stock_agent'],
            'color': '#8b5cf6'
        },
        'user_management': {
            'title': 'User Management',
            'icon': 'people',
            'description': 'Manage system users and permissions',
            'url': 'auth.list_users',
            'roles': ['admin'],
            'color': '#ec4899'
        }
    }
    
    # Process modules based on user role
    accessible_modules = []
    restricted_modules = []
    
    for module_key, module_data in modules.items():
        module_copy = module_data.copy()
        module_copy['key'] = module_key
        module_copy['is_accessible'] = user.role in module_data['roles']
        
        if module_copy['is_accessible']:
            accessible_modules.append(module_copy)
        else:
            restricted_modules.append(module_copy)
    
    all_modules = accessible_modules + restricted_modules
    
    # Get statistics based on user role
    total_machines = Machine.query.filter_by(status='active').count()
    
    # Maintenance schedules
    upcoming_maintenance = MaintenanceSchedule.query.filter(
        MaintenanceSchedule.scheduled_date >= datetime.now().date(),
        MaintenanceSchedule.status.in_(['scheduled', 'overdue'])
    ).count()
    
    overdue_maintenance = MaintenanceSchedule.query.filter(
        MaintenanceSchedule.scheduled_date < datetime.now().date(),
        MaintenanceSchedule.status == 'scheduled'
    ).count()
    
    # Pending demands
    pending_demands = SparePartsDemand.query.filter(
        SparePartsDemand.demand_status.in_(['pending', 'supervisor_review', 'stock_agent_review'])
    ).count()
    
    # Stock alerts
    stock_alerts = StockAlert.query.filter_by(is_read=False).count()
    
    # Critical materials
    critical_materials = Material.query.filter(
        Material.current_stock <= Material.min_stock
    ).count()
    
    # Get recent activities
    recent_demands = SparePartsDemand.query.order_by(
        SparePartsDemand.created_at.desc()
    ).limit(5).all()
    
    recent_maintenance = MaintenanceSchedule.query.order_by(
        MaintenanceSchedule.created_at.desc()
    ).limit(5).all()
    
    stats = {
        'total_machines': total_machines,
        'upcoming_maintenance': upcoming_maintenance,
        'overdue_maintenance': overdue_maintenance,
        'pending_demands': pending_demands,
        'stock_alerts': stock_alerts,
        'critical_materials': critical_materials
    }
    
    return render_template(
        'main/dashboard.html',
        user=user,
        stats=stats,
        modules=all_modules,
        recent_demands=recent_demands,
        recent_maintenance=recent_maintenance
    )

@main_bp.route('/analytics')
@login_required
@role_required('admin')
def analytics():
    """Admin analytics dashboard showing technician performance metrics"""
    from sqlalchemy import func, desc
    
    # Get all technicians and their performance metrics
    technician_stats = db.session.query(
        User.id,
        User.first_name,
        User.last_name,
        User.zone,
        func.count(MaintenanceReport.id).label('total_reports'),
        func.sum(MaintenanceReport.actual_duration_hours).label('total_hours'),
        func.avg(MaintenanceReport.actual_duration_hours).label('avg_hours')
    ).outerjoin(MaintenanceReport, User.id == MaintenanceReport.technician_id)\
     .filter(User.role == 'technician')\
     .group_by(User.id)\
     .all()
    
    # Convert to list of dicts for easier template processing
    technicians = []
    for stat in technician_stats:
        technicians.append({
            'id': stat.id,
            'name': f"{stat.first_name} {stat.last_name}",
            'zone': stat.zone or 'No Zone',
            'total_reports': stat.total_reports or 0,
            'total_hours': stat.total_hours or 0,
            'avg_hours': round(stat.avg_hours, 2) if stat.avg_hours else 0
        })
    
    # Sort to get top performers
    most_reports = sorted(technicians, key=lambda x: x['total_reports'], reverse=True)[:5]
    most_time = sorted(technicians, key=lambda x: x['total_hours'], reverse=True)[:5]
    fastest = sorted(technicians, key=lambda x: x['avg_hours'])[:5]
    
    # Get stats by zone
    zone_stats = db.session.query(
        User.zone,
        func.count(MaintenanceReport.id).label('total_reports'),
        func.sum(MaintenanceReport.actual_duration_hours).label('total_hours'),
        func.count(func.distinct(User.id)).label('technicians')
    ).join(User, User.id == MaintenanceReport.technician_id)\
     .filter(User.zone.isnot(None))\
     .group_by(User.zone)\
     .all()
    
    zones = [{
        'name': stat.zone or 'Unassigned',
        'total_reports': stat.total_reports or 0,
        'total_hours': stat.total_hours or 0,
        'avg_hours': round((stat.total_hours or 0) / (stat.total_reports or 1), 2),
        'technicians': stat.technicians or 0
    } for stat in zone_stats]
    
    # Overall statistics
    total_reports = MaintenanceReport.query.count()
    total_technicians = User.query.filter_by(role='technician').count()
    total_hours = db.session.query(func.sum(MaintenanceReport.actual_duration_hours)).scalar() or 0
    avg_report_duration = round(total_hours / total_reports, 2) if total_reports > 0 else 0
    
    return render_template('main/analytics.html',
                         technicians=technicians,
                         most_reports=most_reports,
                         most_time=most_time,
                         fastest=fastest,
                         zones=zones,
                         total_reports=total_reports,
                         total_technicians=total_technicians,
                         total_hours=round(total_hours, 2),
                         avg_report_duration=avg_report_duration)

@main_bp.route('/modules')
@login_required
def modules():
    user = User.query.get(session['user_id'])
    
    # Define available modules based on user role
    modules_available = {
        'admin': ['stock', 'maintenance', 'demands', 'dashboard', 'users'],
        'supervisor': ['stock', 'maintenance', 'demands', 'dashboard'],
        'technician': ['stock', 'demands'],
        'stock_agent': ['stock', 'demands']
    }
    
    available = modules_available.get(user.role, [])
    
    return render_template('main/modules.html', user=user, available_modules=available)

# Zone & User Management Routes
# Zone Management Routes
@main_bp.route('/zones')
@login_required
@role_required('admin', 'supervisor')
def manage_zones():
    """Manage zones (view all zones and assign to technicians)"""
    page = request.args.get('page', 1, type=int)
    
    zones = Zone.query.paginate(page=page, per_page=20)
    technicians = User.query.filter_by(role='technician').all()
    
    return render_template('main/manage_zones.html', zones=zones, technicians=technicians)

@main_bp.route('/zones/add', methods=['GET', 'POST'])
@login_required
@role_required('admin', 'supervisor')
def add_zone():
    """Add new zone"""
    if request.method == 'POST':
        name = request.form.get('name', '').strip()
        description = request.form.get('description', '').strip()
        location = request.form.get('location', '').strip()
        
        if not name:
            flash('Zone name cannot be empty', 'danger')
            return redirect(url_for('main.add_zone'))
        
        # Check if zone already exists
        existing = Zone.query.filter_by(name=name).first()
        if existing:
            flash(f'Zone "{name}" already exists', 'warning')
            return redirect(url_for('main.add_zone'))
        
        zone = Zone(
            name=name,
            description=description,
            location=location,
            created_by_id=session['user_id']
        )
        
        db.session.add(zone)
        db.session.commit()
        flash(f'Zone "{name}" created successfully!', 'success')
        return redirect(url_for('main.manage_zones'))
    
    return render_template('main/add_zone.html')

@main_bp.route('/zones/<int:zone_id>/edit', methods=['GET', 'POST'])
@login_required
@role_required('admin', 'supervisor')
def edit_zone(zone_id):
    """Edit existing zone"""
    zone = Zone.query.get_or_404(zone_id)
    
    if request.method == 'POST':
        name = request.form.get('name', '').strip()
        description = request.form.get('description', '').strip()
        location = request.form.get('location', '').strip()
        
        if not name:
            flash('Zone name cannot be empty', 'danger')
            return redirect(url_for('main.edit_zone', zone_id=zone_id))
        
        # Check if new name conflicts with another zone
        if name != zone.name:
            existing = Zone.query.filter_by(name=name).first()
            if existing:
                flash(f'Zone "{name}" already exists', 'warning')
                return redirect(url_for('main.edit_zone', zone_id=zone_id))
        
        zone.name = name
        zone.description = description
        zone.location = location
        db.session.commit()
        flash(f'Zone "{name}" updated successfully!', 'success')
        return redirect(url_for('main.manage_zones'))
    
    return render_template('main/edit_zone.html', zone=zone)

@main_bp.route('/zones/<int:zone_id>/delete', methods=['POST'])
@login_required
@role_required('admin', 'supervisor')
def delete_zone(zone_id):
    """Delete zone"""
    zone = Zone.query.get_or_404(zone_id)
    zone_name = zone.name
    
    # Remove zone from technicians
    technicians = User.query.filter(User.zone == zone_name).all()
    for tech in technicians:
        tech.zone = None
    
    db.session.delete(zone)
    db.session.commit()
    flash(f'Zone "{zone_name}" deleted successfully!', 'success')
    return redirect(url_for('main.manage_zones'))

@main_bp.route('/zones/<int:zone_id>/assign/<int:user_id>', methods=['POST'])
@login_required
@role_required('admin', 'supervisor')
def assign_zone_to_technician(zone_id, user_id):
    """Assign zone to technician"""
    zone = Zone.query.get_or_404(zone_id)
    user = User.query.get_or_404(user_id)
    
    if user.role != 'technician':
        flash('Only technicians can be assigned zones.', 'danger')
        return redirect(url_for('main.manage_zones'))
    
    user.zone = zone.name
    db.session.commit()
    flash(f'Zone "{zone.name}" assigned to {user.full_name} successfully!', 'success')
    return redirect(url_for('main.manage_zones'))

@main_bp.route('/technicians')
@login_required
@role_required('admin', 'supervisor')
def list_technicians():
    """List all technicians with their zones"""
    page = request.args.get('page', 1, type=int)
    zone_filter = request.args.get('zone', '')
    
    query = User.query.filter_by(role='technician')
    
    if zone_filter:
        query = query.filter_by(zone=zone_filter)
    
    technicians = query.paginate(page=page, per_page=20)
    
    # Get unique zones
    zones = db.session.query(User.zone).filter(
        User.role == 'technician',
        User.zone.isnot(None)
    ).distinct().all()
    
    return render_template(
        'main/technicians_list.html',
        technicians=technicians,
        zones=[z[0] for z in zones],
        zone_filter=zone_filter
    )

# Stock Management Routes
stock_bp = Blueprint('stock', __name__, url_prefix='/stock')

@stock_bp.route('/')
@login_required
def inventory():
    page = request.args.get('page', 1, type=int)
    category = request.args.get('category', '')
    search = request.args.get('search', '')
    
    query = Material.query
    
    if search:
        query = query.filter(
            (Material.code.ilike(f'%{search}%')) |
            (Material.name.ilike(f'%{search}%'))
        )
    
    if category:
        query = query.filter_by(category=category)
    
    materials = query.paginate(page=page, per_page=20)
    categories = db.session.query(Material.category).distinct().all()
    
    return render_template(
        'stock/inventory.html',
        materials=materials,
        categories=[cat[0] for cat in categories],
        search=search,
        category=category
    )

@stock_bp.route('/add', methods=['GET', 'POST'])
@login_required
@role_required('admin', 'stock_agent')
def add_material():
    if request.method == 'POST':
        material = Material(
            code=request.form.get('code'),
            name=request.form.get('name'),
            description=request.form.get('description'),
            category=request.form.get('category'),
            unit=request.form.get('unit'),
            min_stock=int(request.form.get('min_stock', 10)),
            max_stock=int(request.form.get('max_stock', 100)),
            current_stock=int(request.form.get('current_stock', 0)),
            unit_cost=float(request.form.get('unit_cost', 0)),
            supplier=request.form.get('supplier')
        )
        
        db.session.add(material)
        db.session.commit()
        
        flash(f'Material {material.code} added successfully!', 'success')
        return redirect(url_for('stock.inventory'))
    
    return render_template('stock/add_material.html')

@stock_bp.route('/edit/<int:material_id>', methods=['GET', 'POST'])
@login_required
@role_required('admin', 'stock_agent')
def edit_material(material_id):
    material = Material.query.get_or_404(material_id)
    
    if request.method == 'POST':
        material.name = request.form.get('name', material.name)
        material.description = request.form.get('description', material.description)
        material.category = request.form.get('category', material.category)
        material.unit = request.form.get('unit', material.unit)
        material.min_stock = int(request.form.get('min_stock', material.min_stock))
        material.max_stock = int(request.form.get('max_stock', material.max_stock))
        material.unit_cost = float(request.form.get('unit_cost', material.unit_cost))
        material.supplier = request.form.get('supplier', material.supplier)
        
        db.session.commit()
        flash(f'Material {material.code} updated successfully!', 'success')
        return redirect(url_for('stock.inventory'))
    
    return render_template('stock/edit_material.html', material=material)

@stock_bp.route('/detail/<int:material_id>')
@login_required
def material_detail(material_id):
    material = Material.query.get_or_404(material_id)
    movements = material.movements
    recent_demands = SparePartsDemand.query.filter_by(material_id=material_id).order_by(
        SparePartsDemand.created_at.desc()
    ).limit(10).all()
    
    return render_template(
        'stock/material_detail.html',
        material=material,
        movements=movements,
        recent_demands=recent_demands
    )

@stock_bp.route('/alerts')
@login_required
def stock_alerts():
    page = request.args.get('page', 1, type=int)
    unread_only = request.args.get('unread', 'true').lower() == 'true'
    
    query = StockAlert.query
    if unread_only:
        query = query.filter_by(is_read=False)
    
    alerts = query.order_by(StockAlert.created_at.desc()).paginate(page=page, per_page=20)
    
    return render_template('stock/alerts.html', alerts=alerts, unread_only=unread_only)

@stock_bp.route('/alert/<int:alert_id>/mark-read', methods=['POST'])
@login_required
def mark_alert_read(alert_id):
    alert = StockAlert.query.get_or_404(alert_id)
    alert.is_read = True
    alert.read_at = datetime.utcnow()
    db.session.commit()
    
    flash('Alert marked as read.', 'success')
    return redirect(url_for('stock.stock_alerts'))
@stock_bp.route('/movement-history')
@login_required
def movement_history():
    """View complete stock movement history"""
    page = request.args.get('page', 1, type=int)
    material_id = request.args.get('material_id', '')
    movement_type = request.args.get('type', '')
    
    from app.models import StockMovement
    query = StockMovement.query
    
    if material_id:
        query = query.filter_by(material_id=material_id)
    
    if movement_type:
        query = query.filter_by(movement_type=movement_type)
    
    movements = query.order_by(StockMovement.created_at.desc()).paginate(page=page, per_page=50)
    materials = Material.query.all()
    
    return render_template(
        'stock/movement_history.html',
        movements=movements,
        materials=materials,
        material_id=material_id,
        movement_type=movement_type
    )

@stock_bp.route('/return-material', methods=['GET', 'POST'])
@login_required
def return_material():
    """Return material to stock from a demand"""
    if request.method == 'POST':
        from app.models import MaterialReturn, StockMovement, SparePartsDemand
        
        demand_id = request.form.get('demand_id')
        quantity = int(request.form.get('quantity', 0))
        reason = request.form.get('reason', '')
        condition = request.form.get('condition', 'new')
        
        demand = SparePartsDemand.query.get_or_404(demand_id)
        material = Material.query.get(demand.material_id)
        
        if quantity <= 0 or quantity > (demand.quantity_allocated - demand.quantity_returned):
            flash('Invalid return quantity.', 'danger')
            return redirect(url_for('stock.return_material'))
        
        # Create return record
        material_return = MaterialReturn(
            demand_id=demand_id,
            material_id=demand.material_id,
            quantity_returned=quantity,
            return_reason=reason,
            condition_of_material=condition,
            returned_by_id=session['user_id'],
            return_status='pending'
        )
        
        db.session.add(material_return)
        db.session.commit()
        
        flash('Return request created successfully. Awaiting stock agent approval.', 'success')
        return redirect(url_for('stock.return_material'))
    
    # Get pending demands for the user
    from app.models import SparePartsDemand
    user_id = session['user_id']
    user = User.query.get(user_id)
    
    pending_demands = SparePartsDemand.query.filter(
        (SparePartsDemand.demand_status == 'fulfilled') |
        (SparePartsDemand.demand_status == 'approved_stock_agent'),
        SparePartsDemand.requestor_id == user_id,
        SparePartsDemand.quantity_returned < SparePartsDemand.quantity_allocated
    ).all()
    
    return render_template('stock/return_material.html', demands=pending_demands)

@stock_bp.route('/returns-pending')
@login_required
@role_required('stock_agent', 'admin')
def pending_returns():
    """View pending material returns"""
    from app.models import MaterialReturn
    
    page = request.args.get('page', 1, type=int)
    returns = MaterialReturn.query.filter_by(return_status='pending').order_by(
        MaterialReturn.created_at.desc()
    ).paginate(page=page, per_page=20)
    
    return render_template('stock/pending_returns.html', returns=returns)

@stock_bp.route('/return/<int:return_id>/accept', methods=['POST'])
@login_required
@role_required('stock_agent', 'admin')
def accept_return(return_id):
    """Accept a returned material"""
    from app.models import MaterialReturn, StockMovement
    
    material_return = MaterialReturn.query.get_or_404(return_id)
    material = Material.query.get(material_return.material_id)
    
    if material_return.return_status != 'pending':
        flash('This return has already been processed.', 'warning')
        return redirect(url_for('stock.pending_returns'))
    
    # Update material stock
    material.current_stock += material_return.quantity_returned
    
    # Record stock movement
    movement = StockMovement(
        material_id=material.id,
        movement_type='returned',
        quantity=material_return.quantity_returned,
        reference_id=f"return-{material_return.id}",
        user_id=session['user_id'],
        notes=f'Material returned - {material_return.return_reason}'
    )
    db.session.add(movement)
    
    # Update return status
    material_return.return_status = 'accepted'
    material_return.received_by_id = session['user_id']
    material_return.processed_at = datetime.utcnow()
    
    # Update demand
    demand = SparePartsDemand.query.get(material_return.demand_id)
    if demand:
        demand.quantity_returned += material_return.quantity_returned
        demand.return_date = datetime.utcnow()
    
    db.session.commit()
    flash(f'{material_return.quantity_returned} units of {material.name} accepted and added to stock.', 'success')
    return redirect(url_for('stock.pending_returns'))

@stock_bp.route('/return/<int:return_id>/reject', methods=['POST'])
@login_required
@role_required('stock_agent', 'admin')
def reject_return(return_id):
    """Reject a returned material"""
    from app.models import MaterialReturn
    
    material_return = MaterialReturn.query.get_or_404(return_id)
    
    if material_return.return_status != 'pending':
        flash('This return has already been processed.', 'warning')
        return redirect(url_for('stock.pending_returns'))
    
    material_return.return_status = 'rejected'
    material_return.received_by_id = session['user_id']
    material_return.processed_at = datetime.utcnow()
    material_return.notes = request.form.get('notes', '')
    
    db.session.commit()
    flash('Return request rejected.', 'warning')
    return redirect(url_for('stock.pending_returns'))