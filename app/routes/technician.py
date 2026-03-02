"""
Technician-specific routes for maintenance history and stock views
"""
from flask import Blueprint, render_template, request, redirect, url_for, session, flash
from app.models import db, User, MaintenanceReport, Machine, StockMovement, Material, MaterialReturn, SparePartsDemand
from app.routes.auth import login_required, role_required
from datetime import datetime, timedelta
import uuid

technician_bp = Blueprint('technician', __name__, url_prefix='/technician')

def generate_log_number():
    """Generate unique maintenance log number"""
    timestamp = datetime.utcnow().strftime('%Y%m%d')
    unique_id = str(uuid.uuid4())[:6].upper()
    return f'LOG-{timestamp}-{unique_id}'

@technician_bp.route('/')
@technician_bp.route('/dashboard')
@login_required
@role_required('technician')
def dashboard():
    """Technician dashboard with available stock and maintenance history"""
    user = User.query.get(session['user_id'])
    
    # Get counts for dashboard
    available_stock_count = Material.query.filter(Material.current_stock > 0).count()
    
    # Get technician's recent maintenance logs
    recent_logs = MaintenanceReport.query.filter_by(
        technician_id=session['user_id']
    ).order_by(MaintenanceReport.created_at.desc()).limit(5).all()
    
    recent_maintenance_count = MaintenanceReport.query.filter_by(
        technician_id=session['user_id']
    ).count()
    
    # Count pending returns from this technician
    pending_returns_count = MaterialReturn.query.join(SparePartsDemand).filter(
        SparePartsDemand.requestor_id == session['user_id'],
        MaterialReturn.return_status == 'pending'
    ).count()
    
    return render_template(
        'technician/dashboard.html',
        available_stock_count=available_stock_count,
        recent_logs=recent_logs,
        recent_maintenance_count=recent_maintenance_count,
        pending_returns_count=pending_returns_count
    )

@technician_bp.route('/available-stock')
@login_required
@role_required('technician')
def available_stock():
    """View available stock for technician"""
    page = request.args.get('page', 1, type=int)
    category = request.args.get('category', '')
    search = request.args.get('search', '')
    
    # Build query for available materials (current_stock > 0)
    query = Material.query.filter(Material.current_stock > 0)
    
    if search:
        query = query.filter(
            (Material.code.ilike(f'%{search}%')) |
            (Material.name.ilike(f'%{search}%'))
        )
    
    if category:
        query = query.filter_by(category=category)
    
    # Get total count before pagination
    total_materials = query.count()
    
    # Paginate results
    materials_paginated = query.paginate(page=page, per_page=20)
    
    # Get distinct categories from available materials
    categories_query = db.session.query(Material.category).filter(
        Material.current_stock > 0,
        Material.category.isnot(None)
    ).distinct().all()
    categories = [cat[0] for cat in categories_query]
    
    return render_template(
        'technician/available_stock.html',
        materials=materials_paginated.items,
        categories=categories,
        search=search,
        category=category,
        page=page,
        total_materials=total_materials
    )

@technician_bp.route('/maintenance-history')
@login_required
@role_required('technician')
def maintenance_history():
    """View technician's maintenance history"""
    page = request.args.get('page', 1, type=int)
    machine = request.args.get('machine', '')
    report_type = request.args.get('report_type', '')
    
    # Build query for technician's reports
    query = MaintenanceReport.query.filter_by(technician_id=session['user_id'])
    
    if machine:
        query = query.filter(MaintenanceReport.machine_name.ilike(f'%{machine}%'))
    
    if report_type:
        query = query.filter_by(report_type=report_type)
    
    # Get paginated reports
    reports = query.order_by(MaintenanceReport.created_at.desc()).paginate(page=page, per_page=20)
    
    # Get distinct machines this technician has worked on
    machines_query = db.session.query(MaintenanceReport.machine_name).filter(
        MaintenanceReport.technician_id == session['user_id'],
        MaintenanceReport.machine_name.isnot(None)
    ).distinct().all()
    machines = [m[0] for m in machines_query if m[0]]
    
    return render_template(
        'technician/maintenance_history.html',
        reports=reports.items,
        machines=machines,
        machine=machine,
        report_type=report_type,
        page=page
    )

@technician_bp.route('/material-return', methods=['GET', 'POST'])
@login_required
@role_required('technician')
def material_return():
    """Material return form for technician (similar to demand form)"""
    if request.method == 'POST':
        material_id = request.form.get('material_id')
        quantity = request.form.get('quantity')
        return_reason = request.form.get('return_reason')
        condition_of_material = request.form.get('condition_of_material')
        notes = request.form.get('notes', '')
        
        if not all([material_id, quantity, return_reason, condition_of_material]):
            flash('Please fill all required fields', 'danger')
            return redirect(url_for('technician.material_return'))
        
        try:
            quantity = int(quantity)
            if quantity <= 0:
                flash('Quantity must be positive', 'danger')
                return redirect(url_for('technician.material_return'))
        except ValueError:
            flash('Invalid quantity', 'danger')
            return redirect(url_for('technician.material_return'))
        
        # Find the most recent fulfilled demand for this material by this technician
        demand = SparePartsDemand.query.filter_by(
            requestor_id=session['user_id'],
            material_id=material_id,
            demand_status='fulfilled'
        ).order_by(SparePartsDemand.fulfilled_date.desc()).first()
        
        if not demand:
            flash('No fulfilled demand found for this material', 'warning')
            return redirect(url_for('technician.material_return'))
        
        material = Material.query.get(material_id)
        
        # Create material return
        new_return = MaterialReturn(
            demand_id=demand.id,
            material_id=material_id,
            quantity_returned=quantity,
            return_reason=return_reason,
            condition_of_material=condition_of_material,
            returned_by_id=session['user_id'],
            return_status='pending',
            notes=notes,
            created_at=datetime.utcnow()
        )
        
        db.session.add(new_return)
        db.session.commit()
        
        flash(f'Material return request submitted! Awaiting stock agent approval.', 'success')
        return redirect(url_for('technician.return_status'))
    
    # GET request - show form with fulfilled demands
    fulfilled_demands = SparePartsDemand.query.filter_by(
        requestor_id=session['user_id'],
        demand_status='fulfilled'
    ).order_by(SparePartsDemand.fulfilled_date.desc()).all()
    
    # Format for template
    fulfilled_demands_formatted = []
    for demand in fulfilled_demands:
        material = Material.query.get(demand.material_id)
        fulfilled_demands_formatted.append({
            'material_id': material.id,
            'material_name': material.name,
            'original_quantity': demand.quantity,
            'quantity_returned': demand.quantity_returned or 0
        })
    
    return render_template(
        'technician/material_return.html',
        fulfilled_demands=fulfilled_demands_formatted
    )

@technician_bp.route('/return-status')
@login_required
@role_required('technician')
def return_status():
    """View status of material returns submitted by technician"""
    page = request.args.get('page', 1, type=int)
    status_filter = request.args.get('status', '')
    
    # Build query
    query = MaterialReturn.query.join(SparePartsDemand).filter(
        SparePartsDemand.requestor_id == session['user_id']
    )
    
    if status_filter:
        query = query.filter(MaterialReturn.return_status == status_filter)
    
    # Get paginated returns
    returns_paginated = query.order_by(MaterialReturn.created_at.desc()).paginate(page=page, per_page=20)
    
    # Format returns data for template
    returns_formatted = []
    for ret in returns_paginated.items:
        material = Material.query.get(ret.material_id)
        received_by_user = None
        if ret.received_by_id:
            received_by_user = User.query.get(ret.received_by_id)
        
        returns_formatted.append({
            'id': ret.id,
            'created_at': ret.created_at,
            'material_name': material.name if material else 'Unknown',
            'quantity': ret.quantity_returned,
            'return_reason': ret.return_reason,
            'condition_of_material': ret.condition_of_material,
            'status': ret.return_status,
            'approved_date': ret.approved_date,
            'received_by_name': received_by_user.username if received_by_user else 'Not yet assigned',
            'approved_notes': ret.approved_notes,
            'notes': ret.notes
        })
    
    # Count by status
    all_returns = MaterialReturn.query.join(SparePartsDemand).filter(
        SparePartsDemand.requestor_id == session['user_id']
    )
    
    pending_count = all_returns.filter(MaterialReturn.return_status == 'pending').count()
    approved_count = all_returns.filter(MaterialReturn.return_status == 'accepted').count()
    rejected_count = all_returns.filter(MaterialReturn.return_status == 'rejected').count()
    total_count = all_returns.count()
    
    return render_template(
        'technician/return_status.html',
        returns=returns_formatted,
        status_filter=status_filter,
        pending_count=pending_count,
        approved_count=approved_count,
        rejected_count=rejected_count,
        total_count=total_count,
        page=page
    )
