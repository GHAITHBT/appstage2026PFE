from flask import Blueprint, render_template, request, redirect, url_for, session, flash
from app.models import db, Machine, MaintenanceSchedule, MaintenanceReport, User, SparePartsDemand
from app.routes.auth import login_required, role_required
from datetime import datetime, timedelta
import uuid

maintenance_bp = Blueprint('maintenance', __name__, url_prefix='/maintenance')

@maintenance_bp.route('/')
@login_required
def schedules():
    page = request.args.get('page', 1, type=int)
    status_filter = request.args.get('status', '')
    machine_id = request.args.get('machine_id', '')
    
    user = User.query.get(session['user_id'])
    query = MaintenanceSchedule.query
    
    # Filter based on user role
    if user.role == 'supervisor':
        # Supervisors only see schedules assigned to them
        query = query.filter_by(assigned_supervisor_id=user.id)
    elif user.role == 'technician':
        # Technicians see all schedules (they don't own them, they work on them)
        pass
    
    if status_filter:
        query = query.filter_by(status=status_filter)
    
    if machine_id:
        query = query.filter_by(machine_id=machine_id)
    
    schedules = query.order_by(
        MaintenanceSchedule.scheduled_date.asc()
    ).paginate(page=page, per_page=20)
    
    machines = Machine.query.filter_by(status='active').all()
    
    # Count by status - respect role-based filtering
    status_counts = {}
    count_query = MaintenanceSchedule.query
    if user.role == 'supervisor':
        count_query = count_query.filter_by(assigned_supervisor_id=user.id)
    
    for status in ['scheduled', 'in_progress', 'completed', 'overdue']:
        status_counts[status] = count_query.filter_by(status=status).count()
    
    return render_template(
        'maintenance/schedules.html',
        schedules=schedules,
        machines=machines,
        status_filter=status_filter,
        machine_id=machine_id,
        status_counts=status_counts
    )

@maintenance_bp.route('/create', methods=['GET', 'POST'])
@login_required
@role_required('admin', 'supervisor')
def create_schedule():
    if request.method == 'POST':
        machine_id = request.form.get('machine_id')
        scheduled_date = datetime.strptime(request.form.get('scheduled_date'), '%Y-%m-%d').date()
        
        schedule = MaintenanceSchedule(
            machine_id=machine_id,
            schedule_type=request.form.get('schedule_type'),
            frequency_days=int(request.form.get('frequency_days', 30)),
            scheduled_date=scheduled_date,
            description=request.form.get('description'),
            estimated_duration_hours=int(request.form.get('estimated_duration_hours', 2)),
            assigned_supervisor_id=session['user_id'],
            priority=request.form.get('priority', 'medium'),
            status='scheduled'
        )
        
        db.session.add(schedule)
        db.session.commit()
        
        flash(f'Maintenance schedule created successfully!', 'success')
        return redirect(url_for('maintenance.schedules'))
    
    machines = Machine.query.filter_by(status='active').all()
    return render_template('maintenance/create_schedule.html', machines=machines)

@maintenance_bp.route('/<int:schedule_id>')
@login_required
def schedule_detail(schedule_id):
    schedule = MaintenanceSchedule.query.get_or_404(schedule_id)
    user = User.query.get(session['user_id'])
    
    # Check permission: supervisor must be the assigned supervisor for this schedule
    if user.role == 'supervisor' and schedule.assigned_supervisor_id != user.id:
        flash('You can only view schedules assigned to you.', 'danger')
        return redirect(url_for('maintenance.schedules'))
    
    reports = schedule.maintenance_reports
    demands = SparePartsDemand.query.filter(
        SparePartsDemand.maintenance_report_id.in_(
            [report.id for report in reports]
        )
    ).all() if reports else []
    
    return render_template(
        'maintenance/schedule_detail.html',
        schedule=schedule,
        reports=reports,
        demands=demands
    )

@maintenance_bp.route('/<int:schedule_id>/update-status/<status>', methods=['GET', 'POST'])
@login_required
@role_required('admin', 'supervisor', 'technician')
def update_schedule_status(schedule_id, status):
    schedule = MaintenanceSchedule.query.get_or_404(schedule_id)
    valid_statuses = ['scheduled', 'in_progress', 'completed', 'cancelled', 'overdue']
    
    if status not in valid_statuses:
        flash('Invalid status.', 'danger')
        return redirect(url_for('maintenance.schedule_detail', schedule_id=schedule_id))
    
    schedule.status = status
    db.session.commit()
    
    flash(f'Schedule status updated to {status}.', 'success')
    return redirect(url_for('maintenance.schedule_detail', schedule_id=schedule_id))

@maintenance_bp.route('/<int:schedule_id>/report-type', methods=['GET'])
@login_required
@role_required('technician', 'supervisor')
def choose_report_type(schedule_id):
    """Let technician choose between standard and detailed report"""
    schedule = MaintenanceSchedule.query.get_or_404(schedule_id)
    return render_template('maintenance/choose_report_type.html', schedule=schedule)

@maintenance_bp.route('/<int:schedule_id>/report', methods=['GET', 'POST'])
@login_required
@role_required('technician', 'supervisor')
def create_report(schedule_id):
    schedule = MaintenanceSchedule.query.get_or_404(schedule_id)
    
    if request.method == 'POST':
        action = request.form.get('action', 'draft')  # draft or submit
        
        # Parse times
        actual_start = request.form.get('actual_start_time')
        actual_end = request.form.get('actual_end_time')
        
        actual_start_time = datetime.strptime(f"{request.form.get('report_date')}T{actual_start}", '%Y-%m-%dT%H:%M') if actual_start else None
        actual_end_time = datetime.strptime(f"{request.form.get('report_date')}T{actual_end}", '%Y-%m-%dT%H:%M') if actual_end else None
        
        actual_duration = None
        if actual_start_time and actual_end_time:
            actual_duration = (actual_end_time - actual_start_time).total_seconds() / 3600
        
        technician = User.query.get(session['user_id'])
        
        report = MaintenanceReport(
            schedule_id=schedule_id,
            technician_id=session['user_id'],
            machine_name=schedule.machine.name if schedule.machine else 'Unknown',
            actual_start_time=actual_start_time,
            actual_end_time=actual_end_time,
            actual_duration_hours=actual_duration,
            work_description=request.form.get('work_description'),
            findings=request.form.get('findings'),
            actions_taken=request.form.get('actions_taken'),
            issues_found=request.form.get('issues_found') == 'on',
            issue_description=request.form.get('issue_description'),
            components_replaced=request.form.get('components_replaced'),
            next_maintenance_recommendation=request.form.get('next_maintenance_recommendation'),
            report_type='comprehensive',
            technician_zone=technician.zone,
            machine_condition=request.form.get('machine_condition'),
            machine_condition_after=request.form.get('machine_condition_after'),
            safety_observations=request.form.get('safety_observations'),
            report_status='submitted' if action == 'submit' else 'draft'
        )
        
        db.session.add(report)
        db.session.commit()
        
        if action == 'submit':
            flash('Maintenance report submitted for approval!', 'success')
            return redirect(url_for('maintenance.report_approval', report_id=report.id))
        else:
            flash('Maintenance report saved as draft!', 'info')
            return redirect(url_for('maintenance.report_detail', report_id=report.id))
    
    current_user = User.query.get(session['user_id'])
    return render_template('maintenance/comprehensive_report.html', 
                         schedule=schedule, 
                         current_user=current_user,
                         now=datetime.now())

@maintenance_bp.route('/report/<int:report_id>')
@login_required
def report_detail(report_id):
    report = MaintenanceReport.query.get_or_404(report_id)
    demands = SparePartsDemand.query.filter_by(maintenance_report_id=report.schedule_id).all()
    user = User.query.get(session['user_id'])
    
    return render_template(
        'maintenance/report_detail.html',
        report=report,
        demands=demands,
        user=user
    )

@maintenance_bp.route('/report/<int:report_id>/approval', methods=['GET', 'POST'])
@login_required
@role_required('supervisor', 'admin')
def report_approval(report_id):
    """Handle supervisor approval of maintenance reports"""
    report = MaintenanceReport.query.get_or_404(report_id)
    user = User.query.get(session['user_id'])
    
    # Check permission: supervisor must be either admin or the technician's supervisor
    if user.role == 'supervisor':
        technician = User.query.get(report.technician_id)
        if technician.supervisor_id != user.id:
            flash('You can only approve reports from your assigned technicians.', 'danger')
            return redirect(url_for('maintenance.schedules'))
    
    if request.method == 'POST':
        action = request.form.get('action')
        approval_status = request.form.get('supervisor_approval_status')
        
        report.supervisor_id = session['user_id']
        report.supervisor_approval_status = approval_status
        report.supervisor_approval_date = datetime.utcnow()
        report.supervisor_notes = request.form.get('supervisor_notes')
        
        if approval_status == 'approved':
            report.report_status = 'approved'
            flash('Report approved successfully!', 'success')
        elif approval_status == 'rejected':
            report.report_status = 'rejected'
            flash('Report rejected. Technician has been notified to make revisions.', 'warning')
        
        db.session.commit()
        return redirect(url_for('maintenance.schedules'))
    
    return render_template('maintenance/report_approval.html', report=report)

@maintenance_bp.route('/report/<int:report_id>/submit', methods=['POST'])
@login_required
def submit_report(report_id):
    report = MaintenanceReport.query.get_or_404(report_id)
    
    if report.technician_id != session['user_id'] and session.get('role') != 'admin':
        flash('You can only submit your own reports.', 'danger')
        return redirect(url_for('maintenance.report_detail', report_id=report_id))
    
    report.report_status = 'submitted'
    db.session.commit()
    
    flash('Report submitted for approval!', 'success')
    return redirect(url_for('maintenance.report_detail', report_id=report_id))

@maintenance_bp.route('/report/<int:report_id>/approve', methods=['POST'])
@login_required
@role_required('supervisor', 'admin')
def approve_report(report_id):
    report = MaintenanceReport.query.get_or_404(report_id)
    
    report.report_status = 'approved'
    db.session.commit()
    
    flash('Report approved!', 'success')
    return redirect(url_for('maintenance.report_detail', report_id=report_id))

@maintenance_bp.route('/report/<int:report_id>/reject', methods=['POST'])
@login_required
@role_required('supervisor', 'admin')
def reject_report(report_id):
    report = MaintenanceReport.query.get_or_404(report_id)
    reason = request.form.get('reason', '')
    
    report.report_status = 'rejected'
    db.session.commit()
    
    flash(f'Report rejected. Reason: {reason}', 'warning')
    return redirect(url_for('maintenance.report_detail', report_id=report_id))
