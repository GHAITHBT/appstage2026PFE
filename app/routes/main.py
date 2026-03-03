from flask import Blueprint, render_template, request, redirect, url_for, session, flash
from app.models import db, Material, Machine, MaintenanceSchedule, SparePartsDemand, StockAlert, StockMovement, User, MaterialReturn, Zone, MaintenanceReport
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
        },
        'analytics_maintenance': {
            'title': 'Technician Performance Analytics',
            'icon': 'graph-up',
            'description': 'View technician performance and productivity metrics',
            'url': 'main.analytics',
            'roles': ['admin', 'supervisor'],
            'color': '#667eea'
        },
        'analytics_stock': {
            'title': 'Stock Analytics',
            'icon': 'bar-chart',
            'description': 'View stock levels and inventory metrics',
            'url': 'main.analytics',
            'roles': ['admin', 'supervisor', 'stock_agent'],
            'color': '#06b6d4'
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
@role_required('admin', 'supervisor', 'stock_agent')
def analytics():
    """Analytics dashboard showing key performance indicators and maintenance metrics"""
    from sqlalchemy import func, desc, and_
    from datetime import datetime, timedelta
    
    # Get date range from request or use last 30 days
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')
    
    if start_date:
        try:
            start_date = datetime.strptime(start_date, '%m/%d/%Y')
        except:
            start_date = datetime.utcnow() - timedelta(days=30)
    else:
        start_date = datetime.utcnow() - timedelta(days=30)
    
    if end_date:
        try:
            end_date = datetime.strptime(end_date, '%m/%d/%Y')
        except:
            end_date = datetime.utcnow()
    else:
        end_date = datetime.utcnow()
    
    # ========== KPI CALCULATIONS ==========
    
    # Total Events (maintenance reports)
    total_events = MaintenanceReport.query.filter(
        MaintenanceReport.created_at.between(start_date, end_date)
    ).count()
    
    # Total Downtime in hours
    total_downtime_hours = db.session.query(
        func.sum(MaintenanceReport.actual_duration_hours)
    ).filter(
        MaintenanceReport.created_at.between(start_date, end_date)
    ).scalar() or 0
    total_downtime_hours = round(float(total_downtime_hours), 2)
    
    # Canceled/Rejected Events
    canceled_events = MaintenanceReport.query.filter(
        MaintenanceReport.report_status == 'rejected',
        MaintenanceReport.created_at.between(start_date, end_date)
    ).count()
    
    # Average Downtime in seconds
    avg_downtime_seconds = 0
    if total_events > 0:
        avg_hours = db.session.query(
            func.avg(MaintenanceReport.actual_duration_hours)
        ).filter(
            MaintenanceReport.created_at.between(start_date, end_date)
        ).scalar() or 0
        avg_downtime_seconds = round(float(avg_hours) * 3600, 2)
    
    # Availability Rate (%) - assuming 24hr operation
    availability_rate = 0
    if total_events > 0 and total_downtime_hours > 0:
        operational_hours = (end_date - start_date).total_seconds() / 3600
        availability_rate = round((1 - (total_downtime_hours / operational_hours)) * 100, 2)
        availability_rate = max(0, min(100, availability_rate))  # Clamp 0-100
    
    # Failure Rate (per hour)
    failure_rate = 0
    if total_downtime_hours > 0:
        failure_rate = round(canceled_events / (total_downtime_hours or 1), 2)
    
    # Mean Time To Repair (MTTR) in seconds
    mttr_seconds = 0
    if total_events > 0:
        mttr_hours = db.session.query(
            func.avg(MaintenanceReport.actual_duration_hours)
        ).filter(
            MaintenanceReport.created_at.between(start_date, end_date),
            MaintenanceReport.actual_duration_hours.isnot(None)
        ).scalar() or 0
        mttr_seconds = round(float(mttr_hours) * 3600, 2)
    
    # Mean Time Between Failures (MTBF) in hours
    mtbf_hours = 0
    if canceled_events > 0:
        operational_days = (end_date - start_date).days or 1
        mtbf_hours = round(operational_days * 24 / (canceled_events or 1), 2)
    
    # Most Common Event Type / Report Type
    most_common_event = db.session.query(
        MaintenanceReport.report_type,
        func.count(MaintenanceReport.id).label('count')
    ).filter(
        MaintenanceReport.created_at.between(start_date, end_date)
    ).group_by(MaintenanceReport.report_type)\
     .order_by(desc('count'))\
     .first()
    most_common_event_type = most_common_event[0] if most_common_event else 'N/A'
    
    # Most Active User (technician with most reports)
    most_active_user = db.session.query(
        User.first_name,
        User.last_name,
        func.count(MaintenanceReport.id).label('count')
    ).join(MaintenanceReport, User.id == MaintenanceReport.technician_id)\
     .filter(MaintenanceReport.created_at.between(start_date, end_date))\
     .group_by(User.id)\
     .order_by(desc('count'))\
     .first()
    most_active_user_name = f"{most_active_user[0]} {most_active_user[1]}" if most_active_user else 'N/A'
    
    # Top Resolver (user with highest approval rate)
    top_resolver = db.session.query(
        User.first_name,
        User.last_name,
        func.count(MaintenanceReport.id).label('total'),
        func.sum(func.cast(MaintenanceReport.report_status == 'approved', db.Integer)).label('approved')
    ).join(MaintenanceReport, User.id == MaintenanceReport.technician_id)\
     .filter(MaintenanceReport.created_at.between(start_date, end_date))\
     .group_by(User.id)\
     .order_by(desc('approved'))\
     .first()
    top_resolver_name = f"{top_resolver[0]} {top_resolver[1]}" if top_resolver else 'N/A'
    
    # Most Common Maintenance Type (from issue_description or machine_condition)
    most_common_maintenance = db.session.query(
        MaintenanceReport.machine_condition,
        func.count(MaintenanceReport.id).label('count')
    ).filter(
        MaintenanceReport.created_at.between(start_date, end_date),
        MaintenanceReport.machine_condition.isnot(None)
    ).group_by(MaintenanceReport.machine_condition)\
     .order_by(desc('count'))\
     .first()
    most_common_maintenance_type = most_common_maintenance[0] if most_common_maintenance else 'N/A'
    
    # Events per Machine
    events_per_machine = db.session.query(
        MaintenanceReport.machine_name,
        func.count(MaintenanceReport.id).label('count'),
        func.sum(MaintenanceReport.actual_duration_hours).label('total_hours')
    ).filter(
        MaintenanceReport.created_at.between(start_date, end_date)
    ).group_by(MaintenanceReport.machine_name)\
     .order_by(desc('count'))\
     .limit(10)\
     .all()
    
    events_per_machine = [{
        'machine': m[0] or 'Unknown',
        'count': m[1],
        'hours': round(m[2], 2) if m[2] else 0
    } for m in events_per_machine]
    
    # Events by Type (Status distribution)
    events_by_type = db.session.query(
        MaintenanceReport.report_status,
        func.count(MaintenanceReport.id).label('count')
    ).filter(
        MaintenanceReport.created_at.between(start_date, end_date)
    ).group_by(MaintenanceReport.report_status)\
     .all()
    
    events_by_type = [{
        'status': e[0] or 'Unknown',
        'count': e[1]
    } for e in events_by_type]
    
    # Get technician stats for performance table
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
    
    technicians = []
    for stat in technician_stats:
        technicians.append({
            'id': stat.id,
            'name': f"{stat.first_name} {stat.last_name}",
            'zone': stat.zone or 'No Zone',
            'total_reports': stat.total_reports or 0,
            'total_hours': round(stat.total_hours, 2) if stat.total_hours else 0,
            'avg_hours': round(stat.avg_hours, 2) if stat.avg_hours else 0
        })
    
    most_reports = sorted(technicians, key=lambda x: x['total_reports'], reverse=True)[:5]
    most_time = sorted(technicians, key=lambda x: x['total_hours'], reverse=True)[:5]
    fastest = sorted(technicians, key=lambda x: x['avg_hours'])[:5]
    
    # ========== STOCK KPI CALCULATIONS ==========
    
    # Total Spare Parts in System
    total_spare_parts = Material.query.count()
    
    # Total Stock Value (sum of current_stock * unit_cost)
    total_stock_value = db.session.query(
        func.sum(Material.current_stock * Material.unit_cost)
    ).scalar() or 0
    total_stock_value = round(float(total_stock_value), 2)
    
    # Low Stock Items (current_stock <= min_stock)
    low_stock_items = Material.query.filter(
        Material.current_stock <= Material.min_stock
    ).count()
    
    # Overstock Items (current_stock >= max_stock)
    overstock_items = Material.query.filter(
        Material.current_stock >= Material.max_stock
    ).count()
    
    # Critical Stock Items (current_stock <= reorder_point or no stock at all)
    critical_stock_items = Material.query.filter(
        db.or_(Material.current_stock == 0, Material.current_stock <= Material.reorder_point)
    ).count()
    
    # Average Stock Level
    avg_stock_level = 0
    materials = Material.query.all()
    if materials:
        total_stock = sum([m.current_stock or 0 for m in materials])
        avg_stock_level = round(total_stock / len(materials), 2)
    
    # Stock In Movements (last 30 days)
    total_stock_in = db.session.query(
        func.sum(StockMovement.quantity)
    ).filter(
        StockMovement.movement_type.in_(['in', 'receipt']),
        StockMovement.created_at.between(start_date, end_date)
    ).scalar() or 0
    
    # Stock Out Movements (last 30 days)
    total_stock_out = db.session.query(
        func.sum(StockMovement.quantity)
    ).filter(
        StockMovement.movement_type.in_(['out', 'issue', 'allocated']),
        StockMovement.created_at.between(start_date, end_date)
    ).scalar() or 0
    
    # Most Used / Most Moved Material
    most_moved_material = db.session.query(
        Material.name,
        func.sum(StockMovement.quantity).label('total_moved')
    ).join(StockMovement, Material.id == StockMovement.material_id)\
     .filter(StockMovement.created_at.between(start_date, end_date))\
     .group_by(Material.id)\
     .order_by(desc('total_moved'))\
     .first()
    most_moved_material_name = most_moved_material[0] if most_moved_material else 'N/A'
    most_moved_quantity = most_moved_material[1] if most_moved_material else 0
    
    # Top Material by Value (current_stock * unit_cost)
    top_value_material = db.session.query(
        Material.name,
        (Material.current_stock * Material.unit_cost).label('total_value')
    ).filter(Material.unit_cost.isnot(None))\
     .order_by(desc('total_value'))\
     .first()
    top_value_material_name = top_value_material[0] if top_value_material else 'N/A'
    
    # Stock Alerts Count
    active_alerts = StockAlert.query.filter(
        StockAlert.is_read == False
    ).count()
    
    # Materials by Category
    materials_by_category = db.session.query(
        Material.category,
        func.count(Material.id).label('count'),
        func.sum(Material.current_stock).label('total_stock')
    ).filter(Material.category.isnot(None))\
     .group_by(Material.category)\
     .order_by(desc('count'))\
     .all()
    
    materials_by_category_list = [{
        'category': m[0] or 'Uncategorized',
        'count': m[1],
        'total_stock': m[2] or 0
    } for m in materials_by_category]
    
    # Stock Movement Summary
    movement_summary = db.session.query(
        StockMovement.movement_type,
        func.count(StockMovement.id).label('count'),
        func.sum(StockMovement.quantity).label('total_quantity')
    ).filter(
        StockMovement.created_at.between(start_date, end_date)
    ).group_by(StockMovement.movement_type)\
     .all()
    
    movement_summary_list = [{
        'type': m[0],
        'count': m[1],
        'quantity': m[2]
    } for m in movement_summary]
    
    # Prepare KPI data dictionary
    kpis = {
        'total_events': total_events,
        'total_downtime_hours': total_downtime_hours,
        'canceled_events': canceled_events,
        'avg_downtime_seconds': avg_downtime_seconds,
        'availability_rate': availability_rate,
        'failure_rate': failure_rate,
        'mttr_seconds': mttr_seconds,
        'mtbf_hours': mtbf_hours,
        'most_common_event_type': most_common_event_type,
        'most_active_user': most_active_user_name,
        'top_resolver': top_resolver_name,
        'most_common_maintenance_type': most_common_maintenance_type,
        'events_per_machine': events_per_machine,
        'events_by_type': events_by_type,
        # Stock KPIs
        'total_spare_parts': total_spare_parts,
        'total_stock_value': total_stock_value,
        'low_stock_items': low_stock_items,
        'overstock_items': overstock_items,
        'critical_stock_items': critical_stock_items,
        'avg_stock_level': avg_stock_level,
        'total_stock_in': total_stock_in,
        'total_stock_out': total_stock_out,
        'most_moved_material': most_moved_material_name,
        'most_moved_quantity': most_moved_quantity,
        'top_value_material': top_value_material_name,
        'active_alerts': active_alerts,
        'materials_by_category': materials_by_category_list,
        'movement_summary': movement_summary_list
    }
    
    return render_template('main/analytics.html',
                         kpis=kpis,
                         technicians=technicians,
                         most_reports=most_reports,
                         most_time=most_time,
                         fastest=fastest,
                         start_date=start_date.strftime('%m/%d/%Y'),
                         end_date=end_date.strftime('%m/%d/%Y'))

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