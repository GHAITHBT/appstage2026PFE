from flask import Blueprint, render_template, request, redirect, url_for, session, flash
from app.models import db, SparePartsDemand, Material, User, MaintenanceReport
from app.routes.auth import login_required, role_required
from datetime import datetime
import uuid

demands_bp = Blueprint('demands', __name__, url_prefix='/demands')

def generate_demand_number():
    """Generate unique demand number"""
    timestamp = datetime.now().strftime('%Y%m%d')
    unique_id = str(uuid.uuid4())[:6].upper()
    return f'DEM-{timestamp}-{unique_id}'

@demands_bp.route('/')
@login_required
def list_demands():
    page = request.args.get('page', 1, type=int)
    status_filter = request.args.get('status', '')
    user_id = session['user_id']
    user = User.query.get(user_id)
    
    query = SparePartsDemand.query
    
    # Filter based on user role
    if user.role == 'technician':
        # Technicians see their own demands
        query = query.filter_by(requestor_id=user_id)
    elif user.role == 'supervisor':
        # Supervisors see their own demands + demands assigned to them
        query = query.filter(
            (SparePartsDemand.requestor_id == user_id) |
            (SparePartsDemand.supervisor_id == user_id)
        )
    elif user.role == 'stock_agent':
        # Stock agents see demands assigned to them + pending (no supervisor) + approved by supervisor
        query = query.filter(
            (SparePartsDemand.stock_agent_id == user_id) |
            (SparePartsDemand.demand_status == 'pending') |
            (SparePartsDemand.demand_status == 'approved_supervisor') |
            (SparePartsDemand.demand_status == 'stock_agent_review')
        )
    
    if status_filter:
        query = query.filter_by(demand_status=status_filter)
    
    demands = query.order_by(SparePartsDemand.created_at.desc()).paginate(page=page, per_page=20)
    
    # Status counts
    all_demands_query = SparePartsDemand.query
    if user.role == 'technician':
        all_demands_query = all_demands_query.filter_by(requestor_id=user_id)
    elif user.role == 'supervisor':
        all_demands_query = all_demands_query.filter(
            (SparePartsDemand.requestor_id == user_id) |
            (SparePartsDemand.supervisor_id == user_id)
        )
    
    status_counts = {}
    for status in ['pending', 'supervisor_review', 'approved_supervisor', 'stock_agent_review', 'approved_stock_agent', 'fulfilled']:
        status_counts[status] = all_demands_query.filter_by(demand_status=status).count()
    
    return render_template(
        'demands/list.html',
        demands=demands,
        status_filter=status_filter,
        status_counts=status_counts
    )

@demands_bp.route('/create', methods=['GET', 'POST'])
@login_required
@role_required('technician', 'supervisor', 'stock_agent')
def create_demand():
    if request.method == 'POST':
        materials_data = request.form.getlist('material_id')
        quantities_data = request.form.getlist('quantity')
        
        user = User.query.get(session['user_id'])
        
        # Get supervisor from user's supervisor_id field (set during registration)
        supervisor_id = None
        demand_status = 'pending'
        
        if user.role == 'technician' and user.supervisor_id:
            # If technician has assigned supervisor, route to supervisor
            supervisor_id = user.supervisor_id
            demand_status = 'supervisor_review'
        elif user.role == 'technician':
            # If technician has no supervisor, route directly to stock agent
            demand_status = 'pending'
        
        for material_id, quantity in zip(materials_data, quantities_data):
            if not material_id or not quantity:
                continue
            
            material = Material.query.get(material_id)
            if not material:
                flash(f'Material {material_id} not found.', 'danger')
                continue
            
            demand = SparePartsDemand(
                demand_number=generate_demand_number(),
                maintenance_report_id=request.form.get('maintenance_report_id'),
                requestor_id=session['user_id'],
                material_id=material_id,
                quantity_requested=int(quantity),
                priority=request.form.get('priority', 'medium'),
                reason=request.form.get('reason'),
                supervisor_id=supervisor_id,
                demand_status=demand_status
            )
            
            db.session.add(demand)
        
        db.session.commit()
        flash('Demand(s) created successfully!', 'success')
        return redirect(url_for('demands.list_demands'))
    
    materials = Material.query.all()
    maintenance_reports = MaintenanceReport.query.filter_by(report_status='approved').all()
    
    return render_template(
        'demands/create.html',
        materials=materials,
        maintenance_reports=maintenance_reports
    )

@demands_bp.route('/<int:demand_id>')
@login_required
def detail(demand_id):
    demand = SparePartsDemand.query.get_or_404(demand_id)
    user = User.query.get(session['user_id'])
    
    # Check if user has permission to view
    has_permission = (
        user.role == 'admin' or
        demand.requestor_id == user.id or
        (demand.supervisor_id and demand.supervisor_id == user.id) or
        (demand.stock_agent_id and demand.stock_agent_id == user.id)
    )
    
    # Stock agents can view demands ready for their approval (no stock agent assigned yet)
    if user.role == 'stock_agent' and not demand.stock_agent_id and demand.demand_status in ['pending', 'approved_supervisor']:
        has_permission = True
    
    if not has_permission:
        flash('You do not have permission to view this demand.', 'danger')
        return redirect(url_for('demands.list_demands'))
    
    return render_template('demands/detail.html', demand=demand, user=user)

@demands_bp.route('/<int:demand_id>/supervisor-approve', methods=['POST'])
@login_required
@role_required('supervisor', 'admin')
def supervisor_approve(demand_id):
    demand = SparePartsDemand.query.get_or_404(demand_id)
    user = User.query.get(session['user_id'])
    
    # Check if supervisor is assigned to this demand
    if user.role == 'supervisor' and demand.supervisor_id != user.id:
        flash('This demand is not assigned to you.', 'danger')
        return redirect(url_for('demands.list_demands'))
    
    if demand.demand_status not in ['pending', 'supervisor_review']:
        flash('This demand cannot be approved at this stage.', 'danger')
        return redirect(url_for('demands.detail', demand_id=demand_id))
    
    demand.supervisor_id = session['user_id']
    demand.supervisor_approval = 'approved'
    demand.supervisor_approval_date = datetime.utcnow()
    demand.supervisor_notes = request.form.get('notes', '')
    demand.demand_status = 'approved_supervisor'
    
    db.session.commit()
    flash('Demand approved by supervisor!', 'success')
    return redirect(url_for('demands.detail', demand_id=demand_id))

@demands_bp.route('/<int:demand_id>/supervisor-reject', methods=['POST'])
@login_required
@role_required('supervisor', 'admin')
def supervisor_reject(demand_id):
    demand = SparePartsDemand.query.get_or_404(demand_id)
    user = User.query.get(session['user_id'])
    
    # Check if supervisor is assigned to this demand
    if user.role == 'supervisor' and demand.supervisor_id != user.id:
        flash('This demand is not assigned to you.', 'danger')
        return redirect(url_for('demands.list_demands'))
    
    if demand.demand_status not in ['pending', 'supervisor_review']:
        flash('This demand cannot be rejected at this stage.', 'danger')
        return redirect(url_for('demands.detail', demand_id=demand_id))
    
    demand.supervisor_id = session['user_id']
    demand.supervisor_approval = 'rejected'
    demand.supervisor_approval_date = datetime.utcnow()
    demand.supervisor_notes = request.form.get('notes', '')
    demand.demand_status = 'rejected'
    
    db.session.commit()
    flash('Demand rejected by supervisor.', 'warning')
    return redirect(url_for('demands.detail', demand_id=demand_id))

@demands_bp.route('/<int:demand_id>/stock-review', methods=['POST'])
@login_required
@role_required('stock_agent', 'admin')
def stock_agent_review(demand_id):
    demand = SparePartsDemand.query.get_or_404(demand_id)
    user = User.query.get(session['user_id'])
    
    # Only allow if:
    # 1. This is an admin, OR
    # 2. No stock agent is assigned yet
    if user.role == 'stock_agent' and demand.stock_agent_id:
        flash('This demand is already assigned to another stock agent. You cannot modify it.', 'danger')
        return redirect(url_for('demands.list_demands'))
    
    # Accept either pending (no supervisor) or approved_supervisor (supervisor already approved)
    if demand.demand_status not in ['pending', 'approved_supervisor']:
        flash('This demand is not ready for stock agent review.', 'danger')
        return redirect(url_for('demands.detail', demand_id=demand_id))
    
    demand.stock_agent_id = session['user_id']
    demand.demand_status = 'stock_agent_review'
    
    db.session.commit()
    flash('Demand moved to stock agent review.', 'info')
    return redirect(url_for('demands.detail', demand_id=demand_id))

@demands_bp.route('/<int:demand_id>/stock-approve', methods=['POST'])
@login_required
@role_required('stock_agent', 'admin')
def stock_agent_approve(demand_id):
    demand = SparePartsDemand.query.get_or_404(demand_id)
    user = User.query.get(session['user_id'])
    material = Material.query.get(demand.material_id)
    
    # Only allow approval if:
    # 1. This is an admin, OR
    # 2. No stock agent is assigned yet (new demand), OR
    # 3. This stock agent is already assigned
    if user.role == 'stock_agent' and demand.stock_agent_id and demand.stock_agent_id != user.id:
        flash('This demand is already assigned to another stock agent. You cannot modify it.', 'danger')
        return redirect(url_for('demands.list_demands'))
    
    if demand.demand_status not in ['pending', 'approved_supervisor', 'stock_agent_review']:
        flash('Invalid demand status for approval.', 'danger')
        return redirect(url_for('demands.detail', demand_id=demand_id))
    
    quantity_requested = demand.quantity_requested
    quantity_allocated = min(quantity_requested, material.current_stock)
    
    if quantity_allocated == 0:
        flash('No stock available for this material.', 'danger')
        return redirect(url_for('demands.detail', demand_id=demand_id))
    
    # Update stock
    material.current_stock -= quantity_allocated
    
    # Record movement
    from app.models import StockMovement
    movement = StockMovement(
        material_id=material.id,
        movement_type='fulfilled',
        quantity=quantity_allocated,
        reference_id=f"demand-{demand.id}",
        user_id=session['user_id'],
        notes=f'Allocated for demand {demand.demand_number}'
    )
    db.session.add(movement)
    
    # Update demand
    demand.stock_agent_id = session['user_id']
    demand.stock_agent_approval = 'approved' if quantity_allocated == quantity_requested else 'partial'
    demand.quantity_allocated = quantity_allocated
    demand.stock_agent_approval_date = datetime.utcnow()
    demand.stock_agent_notes = request.form.get('notes', '')
    demand.demand_status = 'approved_stock_agent' if quantity_allocated == quantity_requested else 'partial_allocated'
    demand.fulfilled_date = datetime.utcnow()
    
    db.session.commit()
    flash(f'Demand approved. {quantity_allocated} units allocated and sent to technician.', 'success')
    return redirect(url_for('demands.detail', demand_id=demand_id))

@demands_bp.route('/<int:demand_id>/stock-reject', methods=['POST'])
@login_required
@role_required('stock_agent', 'admin')
def stock_agent_reject(demand_id):
    demand = SparePartsDemand.query.get_or_404(demand_id)
    user = User.query.get(session['user_id'])
    
    # Only allow rejection if:
    # 1. This is an admin, OR
    # 2. No stock agent is assigned yet (new demand), OR
    # 3. This stock agent is already assigned
    if user.role == 'stock_agent' and demand.stock_agent_id and demand.stock_agent_id != user.id:
        flash('This demand is already assigned to another stock agent. You cannot modify it.', 'danger')
        return redirect(url_for('demands.list_demands'))
    
    if demand.demand_status not in ['pending', 'approved_supervisor', 'stock_agent_review']:
        flash('Invalid demand status for rejection.', 'danger')
        return redirect(url_for('demands.detail', demand_id=demand_id))
    
    demand.stock_agent_id = session['user_id']
    demand.stock_agent_approval = 'rejected'
    demand.stock_agent_approval_date = datetime.utcnow()
    demand.stock_agent_notes = request.form.get('notes', '')
    demand.demand_status = 'rejected'
    
    db.session.commit()
    flash('Demand rejected by stock agent. Technician has been notified.', 'warning')
    return redirect(url_for('demands.detail', demand_id=demand_id))
    
    demand.stock_agent_id = session['user_id']
    demand.stock_agent_approval = 'rejected'
    demand.stock_agent_approval_date = datetime.utcnow()
    demand.stock_agent_notes = request.form.get('notes', '')
    demand.demand_status = 'rejected'
    
    db.session.commit()
    flash('Demand rejected by stock agent.', 'warning')
    return redirect(url_for('demands.detail', demand_id=demand_id))
